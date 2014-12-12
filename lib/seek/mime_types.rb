module Seek
  module MimeTypes
    #IF YOU ADD NEW MIME-TYPES, PLEASE ALSO UPDATE THE TEST AT test/units/helpers/mime_types_helper.rb FOR THAT TYPE.
    MIME_MAP = {
        "application/excel" => {:name => "Spreadsheet", :icon_key => "xls_file", :extensions=>["xls"]},
        "application/msword" => {:name => "Word document", :icon_key => "doc_file", :extensions=>["doc"]},
        "application/octet-stream" => {:name => "Binary file", :icon_key => "misc_file", :extensions=>[""]},
        "application/pdf" => {:name => "PDF document", :icon_key => "pdf_file", :extensions=>["pdf"]},
        "application/vnd.excel" => {:name=>"Spreadsheet", :icon_key=>"xls_file", :extensions=>["xls"]},
        "application/msexcel" => {:name => "Spreadsheet", :icon_key => "xls_file", :extensions=>["xls"]},
        "application/vnd.ms-excel" => {:name => "Spreadsheet", :icon_key => "xls_file", :extensions=>["xls"]},
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => {:name => "Word document", :icon_key => "doc_file", :extensions=>["docx"]},
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" => {:name => "PowerPoint presentation", :icon_key => "ppt_file", :extensions=>["pptx"]},
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" => {:name => "Spreadsheet", :icon_key => "xls_file", :extensions=>["xlsx"]},
        "application/vnd.ms-powerpoint" => {:name => "PowerPoint presentation", :icon_key => "ppt_file", :extensions=>["ppt"]},
        "application/zip" => {:name => "Zip file", :icon_key => "zip_file", :extensions=>["zip"]},
        "image/gif" => {:name => "GIF image", :icon_key => "gif_file", :extensions=>["gif"]},
        "image/jpeg" => {:name => "JPEG image", :icon_key => "jpg_file", :extensions=>["jpg","jpeg"]},
        "image/png" => {:name => "PNG image", :icon_key => "png_file", :extensions=>["png"]},
        "image/bmp" => {:name => "BMP image", :icon_key => "bmp_file", :extensions=>["bmp"]},
        "image/svg+xml" => {:name => "SVG image", :icon_key => "svg_file", :extensions=>["svg"]},
        "text/plain" => {:name => "Plain text document", :icon_key => "txt_file", :extensions=>["txt"]},
        "text/csv" => {:name => "Comma-separated values document", :icon_key => "misc_file", :extensions=>["csv"]},
        "text/x-comma-separated-values" => {:name => "Comma-separated values document", :icon_key => "misc_file", :extensions=>["csv"]},
        "application/sbml+xml" => {:name => "SBML and XML document", :icon_key => "xml_file", :extensions=>["xml"]},
        "application/xml" => {:name => "XML document", :icon_key => "xml_file", :extensions=>["xml"]},
        "text/xml" => {:name => "XML document", :icon_key => "xml_file", :extensions=>["xml"]},
        "text/x-objcsrc" => {:name => "Objective C file", :icon_key => "misc_file", :extensions=>["objc"]},
        "application/vnd.oasis.opendocument.presentation" => {:name => "PowerPoint presentation", :icon_key => "ppt_file", :extensions=>["odp"]},
        "application/vnd.oasis.opendocument.presentation-flat-xml" => {:name => "PowerPoint presentation", :icon_key => "ppt_file", :extensions=>["fodp"]},
        "application/vnd.oasis.opendocument.text" => {:name => "Word document", :icon_key => "doc_file", :extensions=>["odt"]},
        "application/vnd.oasis.opendocument.text-flat-xml" => {:name => "Word document", :icon_key => "doc_file", :extensions=>["fodt"]},
        "application/vnd.oasis.opendocument.spreadsheet" => {:name => "Spreadsheet", :icon_key => "xls_file", :extensions=>["ods"]},
        "application/rtf" => {:name => "RTF document", :icon_key => "rtf_file", :extensions=>["rtf"]},
        "text/html" => {:name=>"HTML document",:icon_key=>"html_file",:extensions=>["html"]},
        'application/json' => {:name=>"JSON document",:icon_key=>"misc_file",:extensions=>["json"]}
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

    def mime_extensions(mime)
      mime_find(mime)[:extensions] || []
    end

    def mime_types_for_extension extension
      mime_map.keys.select do |k|
        mime_map[k][:extensions].include?(extension.try(:downcase))
      end
    end

    def mime_map
      MIME_MAP.merge(mime_magic_map) { |ext, seek_value, magic_value| seek_value }
    end

    def mime_magic_map
       mime_magic_map = {}
      MimeMagic::EXTENSIONS.each do |extension, mime|
        if found = MimeMagic.by_extension(extension)
          mime_magic_map[mime] = {}
          mime_magic_map[mime][:name] = found.comment
          mime_magic_map[mime][:icon_key] = "#{extension}_file"
          mime_magic_map[mime][:extensions] = ["#{extension}"]
        end
      end

       mime_magic_map
    end

    protected

    #Defaults to 'Unknown file type' with blank file icon
    def mime_find(mime)
      mime_map[mime] || {:name => "Unknown file type", :icon_key => "misc_file"}
    end

  end
end
