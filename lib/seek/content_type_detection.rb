module Seek
  module ContentTypeDetection
    include Seek::MimeTypes
    extend ActiveSupport::Concern

    included do
      before_create :update_content_mime_type if self.respond_to?(:before_create)
    end

    MAX_SIMULATABLE_SIZE = 5 * 1024 * 1024
    PDF_CONVERTABLE_FORMAT = %w(doc docx ppt pptx odt odp rtf xls xlsx)
    PDF_VIEWABLE_FORMAT = PDF_CONVERTABLE_FORMAT - %w(xls xlsx) + %w(pdf)
    IMAGE_CONVERTABLE_FORMAT = %w(gif jpeg png jpg bmp)
    IMAGE_VIEWABLE_FORMAT = IMAGE_CONVERTABLE_FORMAT + %w(svg)
    TEXT_MIME_TYPES = %w(text/plain text/csv text/x-comma-separated-values text/tab-separated-values
      application/sbml+xml application/xml text/xml application/json text/x-python application/matlab
      text/markdown application/x-ipynb+json)

    def self.viewable_formats
      supported_file_formats = ['pdf']
      supported_file_formats += Seek::ContentTypeDetection::PDF_VIEWABLE_FORMAT if (Seek::Config.pdf_conversion_enabled)
      supported_file_formats += Seek::ContentTypeDetection::IMAGE_VIEWABLE_FORMAT
      supported_file_formats += ['md', 'ipynb']
      supported_file_formats
    end

    def is_text?(blob = self)
      TEXT_MIME_TYPES.include?(blob.content_type)
    end

    def is_cwl?(blob = self)
      blob.original_filename.end_with?('.cwl')
    end

    def is_indexable_text?(blob = self)
      within_text_size_limit?(blob) && is_text?(blob) && blob.file_exists?
    end

    def is_excel?(blob = self)
      is_xls?(blob) || is_xlsx?(blob) || is_xlsm?(blob)
    end

    def is_supported_spreadsheet_format?(blob = self)
      is_excel?(blob) || is_csv?(blob) || is_tsv?(blob)
    end

    # is an Excel file capable of being extacted from
    def is_extractable_excel?(blob = self)
      blob.file_exists? && is_excel?(blob) && within_excel_extraction_size_limit?(blob)
    end

    # is any spreadsheet format, including csv and tsv, that can be extracted from
    def is_extractable_spreadsheet?(blob = self)
      blob.file_exists? && (is_extractable_excel?(blob) || is_csv?(blob) || is_tsv?(blob))
    end

    def is_in_simulatable_size_limit?(blob = self)
      !blob.file_size.nil? && blob.file_size < MAX_SIMULATABLE_SIZE
    end

    def is_xlsx?(blob = self)
      blob.content_type_file_extensions.include?('xlsx')
    end

    def is_xls?(blob = self)
      blob.content_type_file_extensions.include?('xls')
    end

    def is_xlsm?(blob = self)
      blob.content_type_file_extensions.include?('xlsm')
    end

    def is_csv?(blob = self)
      blob.content_type_file_extensions.include?('csv')
    end

    def is_tsv?(blob = self)
      blob.content_type_file_extensions.include?('tsv')
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

    def is_copasi?(blob = self)
      check_content blob, '<copasi'
    end

    def is_xgmml?(blob = self)
      check_content(blob, '<graph') && check_content(blob, '<node')
    end

    def is_image?(blob = self)
      blob.content_type.try(:split, '/').try(:first) == 'image'
    end

    def is_image_convertable?(blob = self)
      (IMAGE_CONVERTABLE_FORMAT & blob.content_type_file_extensions).any?
    end

    def is_pdf_convertable?(blob = self)
      (PDF_CONVERTABLE_FORMAT & blob.content_type_file_extensions).any? && Seek::Config.pdf_conversion_enabled
    end

    def is_image_viewable?(blob = self)
      (IMAGE_VIEWABLE_FORMAT & blob.content_type_file_extensions).any?
    end

    def is_pdf_viewable?(blob = self)
      (PDF_VIEWABLE_FORMAT & blob.content_type_file_extensions).any?
    end

    def is_pdf?(blob = self)
      blob.content_type_file_extensions.include?('pdf')
    end

    def is_markdown?(blob = self)
      blob.content_type_file_extensions.include?('md')
    end

    def is_jupyter_notebook?(blob = self)
      blob.content_type_file_extensions.include?('ipynb')
    end

    def unknown_file_type?(blob = self)
      blob.human_content_type == 'Unknown file type'
    end

    def is_viewable_format?(blob = self)
      !Seek::Renderers::RendererFactory.instance.renderer(blob).is_a?(Seek::Renderers::BlankRenderer)
    end

    def is_content_viewable?(blob = self)
      blob.asset.is_downloadable_asset? && blob.is_viewable_format? && blob.file_exists?
    end

    def update_content_mime_type
      if url
        set_content_type_according_to_url
      elsif file_exists?
        set_content_type_according_to_file
      end
    end

    private

    def within_text_size_limit?(blob)
      !blob.file_size.nil? && blob.file_size < max_indexible_text_size
    end

    # within the size limit that the Apache POI based Excel extractor is able to handle
    def within_excel_extraction_size_limit?(blob = self)
      !blob.file_size.nil? && blob.file_size < max_extractable_spreadsheet_size
    end

    # the max_indexable_text_size in bytes, defaulting to 10Mb
    def max_indexible_text_size
      (Seek::Config.max_indexable_text_size || 10).to_i * 1024 * 1024
    end

    # the max_extractable_spreadsheet_size in bytes, defaulting to 10Mb
    def max_extractable_spreadsheet_size
      (Seek::Config.max_extractable_spreadsheet_size || 10).to_i * 1024 * 1024
    end

    def check_content(blob, str, max_length = 1500)
      char_count = 0
      filepath = blob.filepath
      begin
        File.open(filepath, 'r').each_line do |line|
          char_count += line.length
          # Rails.logger.info("line=>"+line)
          return true if line.downcase.include?(str)
          break if char_count >= max_length
        end
      rescue => exception
        Rails.logger.error("Error reading content_blob contents #{exception.class.name}:#{exception.message}")
      end
      false
    end

    def find_or_keep_type_with_mime_magic
      detected_mime_type = mime_types_for_extension(file_extension).first

      if detected_mime_type.nil? && file_exists?
        detected_mime_type ||= mime_magic_content_type
      end
      detected_mime_type || content_type
    end

    def mime_magic_content_type
      io = File.open(filepath)
      type = MimeMagic.by_magic(io).try(:type) if file_exists?
      io.close
      type
    end

    def set_content_type_according_to_file
      self.content_type = find_or_keep_type_with_mime_magic
    end

    def set_content_type_according_to_url
      type = content_type.blank? ? retrieve_content_type_from_url : content_type

      # strip out the charset, e.g for content-type  "text/html; charset=utf-8"
      type = type.gsub(/;.*/, '').strip
      if type == 'text/html'
        self.is_webpage = true
        self.content_type = type
      end
      self.content_type = type if unknown_file_type?
    rescue => exception
      self.is_webpage = false
      Rails.logger.warn("There was a problem reading the headers for the URL of the content blob: #{url}\n#{exception.class.name}\n\t#{exception.backtrace.join("\n\t")}")
    end

    def retrieve_content_type_from_url
      remote_headers[:content_type] || ''
    end
  end
end
