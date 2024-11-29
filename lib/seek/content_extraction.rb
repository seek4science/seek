module Seek
  module ContentExtraction
    include ContentTypeDetection
    include SysMODB::SpreadsheetExtractor
    include ContentSplit

    def pdf_contents_for_search
      content = []
      if file_exists?
        if is_pdf?
          # copy .dat to .pdf
          FileUtils.cp filepath, filepath('pdf')
        elsif is_pdf_convertable?
          convert_to_pdf
        end
        content = extract_text_from_pdf
        if content.blank?
          []
        else
          content = filter_text_content content
          content = split_content(content, 10 , 5)
        end
      else
        Rails.logger.info("No local file contents for content blob #{id}, so no pdf contents for search available")
      end
      content
    end

    def text_contents_for_search
      content = []
      if file_exists?
        text = File.read(filepath, encoding: 'iso-8859-1')
        unless text.blank?
          content = filter_text_content text
          content = split_content(content,10,5)
        end
      end
      content
    end

    def convert_to_pdf(dat_filepath = filepath, pdf_filepath = filepath('pdf'))
      unless File.exist?(pdf_filepath)
        Rails.logger.info("Converting blob #{id} to pdf")
        # copy dat file to original file extension in order to convert to pdf on this file
        file_extension = mime_extensions(content_type).first
        tmp_file = Tempfile.new(['', '.' + file_extension])
        copied_filepath = tmp_file.path

        FileUtils.cp dat_filepath, copied_filepath

        Libreconv.convert(copied_filepath, pdf_filepath)

        Rails.logger.info("Finished converting blob #{id} to pdf")

      end
    rescue StandardError => e
      Seek::Errors::ExceptionForwarder.send_notification(e, data: { content_blob: self, asset: asset })
      Rails.logger.error("Problem with converting file of content_blob #{id} to pdf - #{e.class.name}:#{e.message}")
    end

    def extract_text_from_pdf
      pdf_filepath = filepath('pdf')
      txt_filepath = filepath('txt')

      return '' unless is_pdf? || is_pdf_convertable?
      return '' unless File.exist?(pdf_filepath)

      begin
        Docsplit.extract_text(pdf_filepath, output: converted_storage_directory) unless File.exist?(txt_filepath)
        File.read(txt_filepath)
      rescue Docsplit::ExtractionFailed => e
        Rails.logger.error("Problem with extracting text from pdf #{id} #{e}")
        ''
      end

    end

    def to_csv(sheet = 1, trim = false)
      return '' unless is_excel?
      spreadsheet_to_csv(filepath, sheet, trim, Seek::Config.jvm_memory_allocation)
    end

    def extract_csv()
      File.read(filepath)
    end

    def to_spreadsheet_xml
      spreadsheet_to_xml(filepath, Seek::Config.jvm_memory_allocation)
    end

    private

    # filters special characters, keeping alphanumeric characters, hyphen ('-'), underscore('_') and newlines
    def filter_text_content(content)
      content.gsub(/[^-_0-9a-z \n]/i, ' ')
    end
  end
end
