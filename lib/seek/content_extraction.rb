module Seek
  module ContentExtraction
    MAXIMUM_PDF_CONVERT_TIME = 3.minutes

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
      unless File.exist?(pdf_filepath) || !Seek::Config.soffice_available?
        # copy dat file to original file extension in order to convert to pdf on this file
        file_extension = mime_extensions(content_type).first
        tmp_file = Tempfile.new(['', '.' + file_extension])
        copied_filepath = tmp_file.path

        FileUtils.cp dat_filepath, copied_filepath

        ConvertOffice::ConvertOfficeFormat.new.convert(copied_filepath, pdf_filepath)
        t = Time.now
        while !File.exist?(pdf_filepath) && (Time.now - t) < MAXIMUM_PDF_CONVERT_TIME
          sleep(1)
        end
      end
    rescue Exception => e
      Rails.logger.error("Problem with converting file of content_blob #{id} to pdf - #{e.class.name}:#{e.message}")
      raise(e)
    end

    def extract_text_from_pdf
      return "" unless is_pdf? || is_pdf_convertable?
      pdf_filepath = filepath('pdf')
      txt_filepath = filepath('txt')

      if File.exist?(pdf_filepath)
        begin
          Docsplit.extract_text(pdf_filepath, output: converted_storage_directory) unless File.exist?(txt_filepath)
          File.read(txt_filepath)
        rescue Docsplit::ExtractionFailed => e
          extract_text_from_pdf if double_check_mime_type
          Rails.logger.error("Problem with extracting text from pdf #{id} #{e}")
          ""
        end
      end
    end

    def to_csv(sheet = 1, trim = false)
      return '' unless is_excel?
      begin
        spreadsheet_to_csv(File.open(filepath), sheet, trim, Seek::Config.jvm_memory_allocation)
      rescue SysMODB::SpreadsheetExtractionException
        to_csv(sheet, trim) if double_check_mime_type
      end
    end

    def extract_csv()
      File.read(filepath)
    end

    def to_spreadsheet_xml
      begin
        spreadsheet_to_xml(File.open(filepath), Seek::Config.jvm_memory_allocation)
      rescue SysMODB::SpreadsheetExtractionException=>e
        if double_check_mime_type
          to_spreadsheet_xml
        else
          raise e
        end
      end
    end

    private

    # checks the type using mime magic, and updates if found to be different. This is to help cases where extraction
    # fails due to the mime type being incorrectly set
    #
    # @return boolean - the mime type was changed
    def double_check_mime_type
      suggested_type = mime_magic_content_type
      if suggested_type && suggested_type != content_type
        update_column(:content_type, suggested_type)
        true
      else
        false
      end
    end


    # filters special characters, keeping alphanumeric characters, hyphen ('-'), underscore('_') and newlines
    def filter_text_content(content)
      content.gsub(/[^-_0-9a-z \n]/i, ' ')
    end
  end
end
