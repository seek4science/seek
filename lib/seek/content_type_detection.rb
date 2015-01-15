module Seek
  module ContentTypeDetection

    include Seek::MimeTypes

    MAX_EXTRACTABLE_SPREADSHEET_SIZE=(Seek::Config.max_extractable_spreadsheet_size || 10).to_i*1024*1024
    MAX_SIMULATABLE_SIZE=5*1024*1024
    PDF_CONVERTABLE_FORMAT = %w[doc docx ppt pptx odt odp rtf txt xls xlsx]
    PDF_VIEWABLE_FORMAT = PDF_CONVERTABLE_FORMAT - %w[xls xlsx]
    IMAGE_VIEWABLE_FORMAT = %w[gif jpeg png jpg bmp svg]

    def is_excel? blob=self
      is_xls?(blob) || is_xlsx?(blob)
    end

    def is_extractable_spreadsheet? blob=self
      within_size_limit(blob) && is_excel?(blob)
    end

    def is_in_simulatable_size_limit? blob=self
      !blob.filesize.nil? && blob.filesize < MAX_SIMULATABLE_SIZE
    end

    def is_xlsx? blob=self
      mime_extensions(blob.content_type).include?("xlsx")
    end

    def is_xls? blob=self
      mime_extensions(blob.content_type).include?("xls")
    end

    def is_jws_dat? blob=self
      check_content blob,"begin name",25000
    end

    def is_sbml? blob=self
      check_content blob,"<sbml"
    end

    def is_xgmml? blob=self
      check_content(blob,"<graph") && check_content(blob,"<node")
    end

    def is_pdf? blob=self
      mime_extensions(blob.content_type).include?('pdf')
    end

    def is_image? blob=self
      blob.content_type.try(:split, '/').try(:first) == 'image'
    end

    def is_pdf_convertable? blob=self
      !(PDF_CONVERTABLE_FORMAT & mime_extensions(blob.content_type)).empty? && Seek::Config.pdf_conversion_enabled
    end

    def is_viewable_format? blob=self
      if Seek::Config.pdf_conversion_enabled
        !(((PDF_VIEWABLE_FORMAT + IMAGE_VIEWABLE_FORMAT) << 'pdf') & mime_extensions(blob.content_type)).empty?
      else
        !((IMAGE_VIEWABLE_FORMAT << 'pdf') & (mime_extensions(blob.content_type))).empty?
      end
    end

    def is_content_viewable? blob=self
       blob.asset.is_downloadable_asset? && blob.is_viewable_format?
    end

    private

    def within_size_limit blob
      !blob.filesize.nil? && blob.filesize < MAX_EXTRACTABLE_SPREADSHEET_SIZE
    end

    def check_content blob, str, max_length=1500
      char_count=0
      filepath=blob.filepath
      begin
        f = File.open(filepath, "r")
        f.each_line do |line|
          char_count += line.length
          return true if line.downcase.include?(str)
          break if char_count>=max_length
        end
      rescue Exception=>e
        Rails.logger.error("Error reading content_blob contents #{e.class.name}:#{e.message}")
      end
      false
    end

  end
end
