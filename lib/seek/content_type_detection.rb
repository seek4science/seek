module Seek
  module ContentTypeDetection
    include Seek::MimeTypes
    extend ActiveSupport::Concern

    included do
      before_create :update_content_mime_type if self.respond_to?(:before_create)
    end

    MAX_EXTRACTABLE_SPREADSHEET_SIZE = (Seek::Config.max_extractable_spreadsheet_size || 10).to_i * 1024 * 1024
    MAX_SIMULATABLE_SIZE = 5 * 1024 * 1024
    PDF_CONVERTABLE_FORMAT = %w(doc docx ppt pptx odt odp rtf txt xls xlsx csv tsv)
    PDF_VIEWABLE_FORMAT = PDF_CONVERTABLE_FORMAT - %w(xls xlsx)
    IMAGE_VIEWABLE_FORMAT = %w(gif jpeg png jpg bmp svg)
    TEXT_MIME_TYPES = %w(text/plain text/csv text/x-comma-separated-values text/tab-separated-values application/sbml+xml application/xml text/xml application/json)

    def is_text?(blob = self)
      type = blob.content_type
      TEXT_MIME_TYPES.include?(type)
    end

    def is_excel?(blob = self)
      is_xls?(blob) || is_xlsx?(blob)
    end

    def is_extractable_spreadsheet?(blob = self)
      within_size_limit(blob) && is_excel?(blob) && blob.file_exists?
    end

    def is_in_simulatable_size_limit?(blob = self)
      !blob.file_size.nil? && blob.file_size < MAX_SIMULATABLE_SIZE
    end

    def is_xlsx?(blob = self)
      mime_extensions(blob.content_type).include?('xlsx')
    end

    def is_xls?(blob = self)
      mime_extensions(blob.content_type).include?('xls')
    end

    def is_binary?(blob = self)
      blob.content_type == 'application/octet-stream'
    end

    def human_content_type(blob = self)
      mime_nice_name(blob.content_type)
    end

    def is_jws_dat?(blob = self)
      check_content blob, 'begin name', 25_000
    end

    def is_sbml?(blob = self)
      check_content blob, '<sbml'
    end

    def is_xgmml?(blob = self)
      check_content(blob, '<graph') && check_content(blob, '<node')
    end

    def is_pdf?(blob = self)
      mime_extensions(blob.content_type).include?('pdf')
    end

    def is_image?(blob = self)
      blob.content_type.try(:split, '/').try(:first) == 'image'
    end

    def is_pdf_convertable?(blob = self)
      !(PDF_CONVERTABLE_FORMAT & mime_extensions(blob.content_type)).empty? && Seek::Config.pdf_conversion_enabled
    end

    def unknown_file_type?(blob = self)
      blob.human_content_type == 'Unknown file type'
    end

    def is_viewable_format?(blob = self)
      if Seek::Config.pdf_conversion_enabled
        !(((PDF_VIEWABLE_FORMAT + IMAGE_VIEWABLE_FORMAT) << 'pdf') & mime_extensions(blob.content_type)).empty?
      else
        !((IMAGE_VIEWABLE_FORMAT << 'pdf') & (mime_extensions(blob.content_type))).empty?
      end
    end

    def is_content_viewable?(blob = self)
      blob.asset.is_downloadable_asset? && blob.is_viewable_format? && blob.file_exists?
    end

    def update_content_mime_type
      if url
        set_content_type_according_to_url
      elsif (is_binary? || unknown_file_type?) && file_exists?
        set_content_type_according_to_file
      end
    end

    private

    def within_size_limit(blob)
      !blob.file_size.nil? && blob.file_size < MAX_EXTRACTABLE_SPREADSHEET_SIZE
    end

    def check_content(blob, str, max_length = 1500)
      char_count = 0
      filepath = blob.filepath
      begin
        File.open(filepath, 'r').each_line do |line|
          char_count += line.length
          return true if line.downcase.include?(str)
          break if char_count >= max_length
        end
      rescue => exception
        Rails.logger.error("Error reading content_blob contents #{exception.class.name}:#{exception.message}")
      end
      false
    end

    def find_or_keep_type_with_mime_magic
      mime = MimeMagic.by_extension(file_extension)
      mime ||= MimeMagic.by_magic(File.open filepath) if file_exists?
      mime.try(:type) || content_type
    end

    def set_content_type_according_to_file
      self.content_type = find_or_keep_type_with_mime_magic
    end

    def set_content_type_according_to_url
      type = retrieve_content_type_from_url
      if type == 'text/html'
        self.is_webpage = true
        self.content_type = type
      end
      self.content_type = type if unknown_file_type?
    rescue => exception
      self.is_webpage = false
      Rails.logger.warn("There was a problem reading the headers for the URL of the content blob = #{url}")
    end
  end
end
