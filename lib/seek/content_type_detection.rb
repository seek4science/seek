module Seek
  module ContentTypeDetection

    include Seek::MimeTypes

    MAX_EXTRACTABLE_SPREADSHEET_SIZE=1*1024*1024

    def is_excel? blob=self
      is_xls?(blob) || is_xlsx?(blob)
    end

    def is_extractable_spreadsheet? blob=self
      within_size_limit(blob) && is_excel?(blob)
    end

    def is_xlsx? blob=self
      mime_extension(blob.content_type) == "xlsx"
    end

    def is_xls? blob=self
      mime_extension(blob.content_type) == "xls"
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