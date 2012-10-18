module Seek
  module PdfExtraction
    MAXIMUM_PDF_CONVERT_TIME = 30.seconds

    def pdf_contents_for_search
      content = nil
      if file_exists?
        if is_pdf_convertable?
           convert_to_pdf
           content = extract_text_from_pdf
        end
      else
        Rails.logger.error("Unable to find file contents for content blob #{id}")
      end
      content
    end

    def convert_to_pdf
      pdf_filepath = filepath('pdf')
      Rails.logger.error  "Looking for pdf at #{pdf_filepath}"
      begin
        unless File.exists?(pdf_filepath)
          Rails.logger.error  "pdf doesn't exist, will have to converting it.'"
          #copy dat file to original file extension in order to convert to pdf on this file
          dat_filepath = filepath
          file_extension = mime_extension(content_type)
          tmp_file = Tempfile.new storage_filename(file_extension)
          copied_filepath = tmp_file.path

          FileUtils.cp dat_filepath, copied_filepath
          Rails.logger.error "copied to #{copied_filepath} ready for conversion - copied file exists? = #{File.exists?(copied_filepath)}"

          ConvertOffice::ConvertOfficeFormat.new.convert(copied_filepath,pdf_filepath)
          Rails.logger.error  "should now be converted. is the file there? = #{File.exists?(pdf_filepath)}"
          t = Time.now
          while !File.exists?(pdf_filepath) && (Time.now - t) < MAXIMUM_PDF_CONVERT_TIME
            sleep(1)
            Rails.logger.error  "waited for a bit = #{File.exists?(pdf_filepath)}"
          end
          Rails.logger.error  "finished waiting. is the file there? = #{File.exists?(pdf_filepath)}"
        end
      rescue Exception=> e
        Rails.logger.error("Problem with converting file of content_blob #{id} to pdf - #{e.class.name}:#{e.message}")
        raise(e)# if Rails.env=="test"
      end
    end

    private

    def extract_text_from_pdf
      output_directory = storage_directory
      pdf_filepath = filepath('pdf')
      txt_filepath = filepath('txt')
      content = nil
      if File.exists?(pdf_filepath)
        begin
          Docsplit.extract_text(pdf_filepath, :output => output_directory) unless File.exists?(txt_filepath)
          content = File.open(txt_filepath).read
          unless content.blank?
            filter_text_content content
          else
            content
          end
        rescue Exception => e
          Rails.logger.error("Problem with extracting text from pdf #{id} #{e}")
          nil
        end
      end
    end

    #filters special characters \n \f
    def filter_text_content content
      special_characters = ['\n', '\f']
      special_characters.each do |sc|
        content.gsub!(/#{sc}/, '')
      end
      content
    end
  end
end
