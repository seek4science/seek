module MimeTypesHelper
  MIME_MAP = {
    "application/excel" => {:name => "Spreadsheet", :icon_key => "xls_file"},
    "application/msword" => {:name => "Word document", :icon_key => "doc_file"},
    "application/octet-stream" => {:name => "Unknown file type", :icon_key => "misc_file"},
    "application/pdf" => {:name => "PDF file", :icon_key => "pdf_file"},
    "application/vnd.ms-excel" => {:name => "Spreadsheet", :icon_key => "xls_file"},
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => {:name => "DocX document", :icon_key => "doc_file"},
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" => {:name => "XLSX Spreadsheet", :icon_key => "xls_file"},
    "application/vnd.ms-powerpoint" => {:name => "PowerPoint presentation", :icon_key => "ppt_file"},
    "application/zip" => {:name => "Zip file", :icon_key => "zip_file"},
    "image/gif" => {:name => "GIF image", :icon_key => "gif_file"},
    "image/jpeg" => {:name => "JPG image", :icon_key => "jpg_file"},
    "image/png" => {:name => "PNG image", :icon_key => "png_file"},
    "text/plain" => {:name => "Text file", :icon_key => "txt_file"},
    "text/x-comma-separated-values" => {:name => "CSV file", :icon_key => "misc_file"},
    "text/xml" => {:name => "XML file", :icon_key => "xml_file"},
    "text/x-objcsrc" => {:name => "Objective C file", :icon_key => "misc_file"}
  }
  
  #Defaults to 'Unknown file type' with blank file icon
  def mime_find(mime)
    return MIME_MAP[mime] || {:name => "Unknown file type", :icon_key => "misc_file"}    
  end

  #Get a nice, human readable name for the MIME type
  def mime_nice_name(mime)
    return mime_find(mime)[:name]
  end
  
  #Get the appropriate file icon for the MIME type
  def mime_icon_url(mime)
    return icon_filename_for_key(mime_find(mime)[:icon_key])
  end
end
