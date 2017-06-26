module Seek
  module ContentExtraction
    MAXIMUM_PDF_CONVERT_TIME = 3.minutes

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
      else
        Rails.logger.info("No local file contents for content blob #{id}, so no pdf contents for search available")
      end
      content
    end

    def text_contents_for_search
      content = []
      if file_exists?
        text = File.read(filepath)
        unless text.blank?
          content = filter_text_content text
          content = split_content(content)
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
      output_directory = converted_storage_directory
      pdf_filepath = filepath('pdf')
      txt_filepath = filepath('txt')

      if File.exist?(pdf_filepath)
        begin
          Docsplit.extract_text(pdf_filepath, output: output_directory) unless File.exist?(txt_filepath)
          content = File.read(txt_filepath)
          if content.blank?
            []
          else
            content = filter_text_content content
            split_content content
          end
        rescue Exception => e
          Rails.logger.error("Problem with extracting text from pdf #{id} #{e}")
          []
        end
      end
    end

    private

    def split_content(content, delimiter = "\n")
      content.split(delimiter).reject { |str| (str.blank? || str.length > 50) }.uniq
    end

    # filters special characters, keeping alphanumeric characters, hyphen ('-'), underscore('_') and newlines
    def filter_text_content(content)
      content.gsub(/[^-_0-9a-z \n]/i, '')
    end
  end
end
