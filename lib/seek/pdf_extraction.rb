module Seek
  module PdfExtraction
    include Seek::MimeTypes

    MAXIMUM_PDF_CONVERT_TIME = 10.minutes
    PDF_CONVERTABLE_FORMAT = %w[doc docx ppt pptx odt odp rtf txt]

    def is_content_viewable?
      asset.is_downloadable_asset? && asset.can_download? && is_viewable_format? && !filesize.nil?
    end

    def is_viewable_format?
      (PDF_CONVERTABLE_FORMAT << 'pdf').include?(mime_extension(content_type))
    end

    def is_pdf_convertable?
      PDF_CONVERTABLE_FORMAT.include?(mime_extension(content_type))
    end

    def is_pdf?
      mime_extension(content_type) == 'pdf'
    end

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
      dat_filepath = filepath
      pdf_filepath = filepath('pdf')
      begin
        unless file_exists?(pdf_filepath)
          #copy dat file to original file extension in order to convert to pdf on this file
          file_extension = mime_extension(content_type)
          copied_filepath = filepath(file_extension)
          FileUtils.cp dat_filepath, copied_filepath
          ConvertOffice::ConvertOfficeFormat.new.convert(copied_filepath,pdf_filepath)

          t = Time.now
          while !file_exists?(pdf_filepath) || (Time.now - t) > MAXIMUM_PDF_CONVERT_TIME
            sleep(1)
          end
          #remove copied file
          FileUtils.rm copied_filepath
        end
      rescue Exception=> e
        Rails.logger.error("Problem with converting file of content_blob #{id} to pdf")
      end
  end

    private

    def extract_text_from_pdf
      output_directory = directory_storage_path
      pdf_filepath = filepath('pdf')
      txt_filepath = filepath('txt')
      content = nil
      if file_exists?(pdf_filepath)
        begin
          Docsplit.extract_text(pdf_filepath, :output => output_directory) unless file_exists?(txt_filepath)
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
