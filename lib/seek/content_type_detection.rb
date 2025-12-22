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

    # Get all viewable formats
    def self.viewable_formats
      supported_file_formats = ['pdf']
      supported_file_formats += Seek::ContentTypeDetection::PDF_VIEWABLE_FORMAT if (Seek::Config.pdf_conversion_enabled)
      supported_file_formats += Seek::ContentTypeDetection::IMAGE_VIEWABLE_FORMAT
      supported_file_formats += ['md', 'ipynb']
      supported_file_formats
    end

    # MIME Type Detection
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

    # Ensure file is extractable spreadsheet
    def is_extractable_excel?(blob = self)
      blob.stored_in_shrine? && is_excel?(blob) && within_excel_extraction_size_limit?(blob)
    end

    def is_extractable_spreadsheet?(blob = self)
      blob.stored_in_shrine? && (is_extractable_excel?(blob) || is_csv?(blob) || is_tsv?(blob))
    end

    def is_unzippable_datafile?(blob = self)
      blob.stored_in_shrine? && (is_zip?(blob) || is_tar?(blob) || is_tgz?(blob) || is_tbz2?(blob) || is_7zip?(blob) || is_txz?(blob))
    end

    # File size validation
    def is_in_simulatable_size_limit?(blob = self)
      !blob.file_size.nil? && blob.file_size < MAX_SIMULATABLE_SIZE
    end
    
    def is_zip?(blob = self)
      blob.content_type_file_extensions.include?('zip')
    end

    def is_7zip?(blob = self)
      blob.content_type_file_extensions.include?('7z')
    end

    def is_tar?(blob = self)
      blob.content_type_file_extensions.include?('tar')
    end

    def is_tgz?(blob = self)
      blob.content_type_file_extensions.include?('tgz')
    end

    def is_tbz2?(blob = self)
      blob.content_type_file_extensions.include?('tbz2')
    end

    def is_txz?(blob = self)
      #Switched off until unzip.rb file is fixed
      false
      #blob.content_type_file_extensions.include?('txz')
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

    def is_morpheus?(blob = self)
      check_content blob, '<morpheusmodel'
    end

    def is_xgmml?(blob = self)
      check_content(blob, '<graph') && check_content(blob, '<node')
    end

    def is_image?(blob = self)
      blob.content_type.try(:split, '/').try(:first) == 'image'
    end

    def is_cff?(blob = self)
      blob.content_type_file_extensions.include?('cff')
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

    def is_svg?(blob = self)
      blob.content_type_file_extensions.include?('svg')
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

    def is_content_remotely_viewable?(blob = self)
      return false unless blob.stored_in_shrine?

      # Only certain formats are viewable
      blob.is_viewable_format?
    end

    # Set content type for S3 files
    def update_content_mime_type
      if url
        set_content_type_according_to_url
      elsif stored_in_shrine?
        set_content_type_according_to_shrine_metadata
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

    # Set MIME type using Shrine metadata
    def set_content_type_according_to_shrine_metadata
      if respond_to?(:file_attacher) && file_attacher&.attached?
        self.content_type = file.metadata['mime_type'] || 'application/octet-stream'
      end
    end

    # Set MIME type using URL headers
    def set_content_type_according_to_url
      type = content_type.blank? ? retrieve_content_type_from_url : content_type
      type = type.gsub(/;.*/, '').strip # Remove charset info
      if type == 'text/html'
        self.is_webpage = true
        self.content_type = type
      end
      self.content_type = type if unknown_file_type?
    rescue => exception
      self.is_webpage = false
      Rails.logger.warn("Problem reading headers: #{exception.class.name}: #{exception.message}")
    end

    # Fetch content type from URL via headers
    def retrieve_content_type_from_url
      remote_headers[:content_type] || ''
    end
  end
end