module Seek
  module MimeTypes
    #IF YOU ADD NEW MIME-TYPES, PLEASE ALSO UPDATE THE TEST AT test/units/helpers/mime_types_helper.rb FOR THAT TYPE.
    MIME_MAP = {
        "application/excel" => {:name => "Spreadsheet", :icon_key => "xls_file", :extension=>"xls"},
        "application/msword" => {:name => "Word document", :icon_key => "doc_file", :extension=>"doc"},
        "application/octet-stream" => {:name => "Binary file type", :icon_key => "misc_file", :extension=>""},
        "application/pdf" => {:name => "PDF document", :icon_key => "pdf_file", :extension=>"pdf"},
        "application/vnd.excel" => {:name=>"Spreadsheet", :icon_key=>"xls_file", :extension=>"xls"},
        "application/msexcel" => {:name => "Spreadsheet", :icon_key => "xls_file", :extension=>"xls"},
        "application/vnd.ms-excel" => {:name => "Spreadsheet", :icon_key => "xls_file", :extension=>"xls"},
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => {:name => "Word document", :icon_key => "doc_file", :extension=>"docx"},
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" => {:name => "Spreadsheet", :icon_key => "xls_file", :extension=>"xlsx"},
        "application/vnd.ms-powerpoint" => {:name => "PowerPoint presentation", :icon_key => "ppt_file", :extension=>"ppt"},
        "application/zip" => {:name => "Zip file", :icon_key => "zip_file", :extension=>"zip"},
        "image/gif" => {:name => "GIF image", :icon_key => "gif_file", :extension=>"gif"},
        "image/jpeg" => {:name => "JPG image", :icon_key => "jpg_file", :extension=>"jpeg"},
        "image/png" => {:name => "PNG image", :icon_key => "png_file", :extension=>"png"},
        "text/plain" => {:name => "Plain text file", :icon_key => "txt_file", :extension=>"txt"},
        "text/x-comma-separated-values" => {:name => "Comma-seperated-values file", :icon_key => "misc_file", :extension=>"csv"},
        "text/xml" => {:name => "XML document", :icon_key => "xml_file", :extension=>"xml"},
        "application/xml" => {:name => "XML document", :icon_key => "xml_file", :extension=>"xml"},
        "text/x-objcsrc" => {:name => "Objective C file", :icon_key => "misc_file", :extension=>"objc"}
    }

    #Get a nice, human readable name for the MIME type
    def mime_nice_name(mime)
      mime_find(mime)[:name]
    end

    def mime_icon_key mime
      mime_find(mime)[:icon_key]
    end

    #Get the appropriate file icon for the MIME type
    def mime_icon_url(mime)
      icon_filename_for_key(mime_icon_key(mime))
    end

    def mime_extension(mime)
      mime_find(mime)[:extension]
    end

    def mime_types_for_extension extension
      MIME_MAP.keys.select do |k|
        MIME_MAP[k][:extension]==extension
      end
    end

    protected

    #Defaults to 'Unknown file type' with blank file icon
    def mime_find(mime)
      MIME_MAP[mime] || {:name => "Unknown file type", :icon_key => "misc_file"}
    end
  end
end