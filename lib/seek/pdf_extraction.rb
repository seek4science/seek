module Seek
  module PdfExtraction
    include Seek::MimeTypes

    def is_downloadable_pdf?
      is_downloadable_asset? && can_download? && is_pdf? && !content_blob.filesize.nil?
    end

    def is_content_viewable?
      is_downloadable_asset? && can_download? && is_viewable_format? && !content_blob.filesize.nil?
    end

    def is_viewable_format?
      #FIXME: should be updated to use mime_helper, rather than redefining the mime types here. A new module may be required that consolidates format related stuff
      viewable_formats= %w[pdf doc ppt odt odp]
      viewable_formats.include?(mime_extension(content_type))
    end

    def is_pdf?
      mime_extension(content_type) == 'pdf'
    end

    def pdf_contents_for_search obj=self
      content_blob = obj.content_blob
      content = nil
      if content_blob.file_exists?
        if obj.is_viewable_format?
            begin
              output_directory = content_blob.directory_storage_path
              dat_filepath = content_blob.filepath
              pdf_filepath = content_blob.filepath('pdf')
              txt_filepath = content_blob.filepath('txt')
              Docsplit.extract_pdf(dat_filepath, :output => output_directory) unless content_blob.file_exists?(pdf_filepath)
              Docsplit.extract_text(pdf_filepath, :output => output_directory) unless content_blob.file_exists?(txt_filepath)
              content = File.open(txt_filepath).read
              unless content.blank?
                filter_text_content content
              else
                content
              end
            rescue Exception => e
              Rails.logger.error("Error processing content for content_blob #{obj.content_blob.id} #{e}")
              raise e unless Rails.env=="production"
              nil
            end
        end
      else
        Rails.logger.error("Unable to find file contents for #{obj.class.name} #{obj.id}")
      end
      content
    end

    private

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
