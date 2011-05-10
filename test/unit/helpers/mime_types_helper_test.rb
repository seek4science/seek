require 'test_helper'

class MimeTypesHelperTest < ActionView::TestCase
  include MimeTypesHelper
  include ImagesHelper
  
  MISC=%w{application/octet-stream application/zip text/x-objcsrc}
  EXCEL=%w{application/excel application/vnd.excel application/vnd.ms-excel}
  EXCELX=%w{application/vnd.openxmlformats-officedocument.spreadsheetml.sheet}
  DOC=%w{application/msword}
  DOCX=%w{application/vnd.openxmlformats-officedocument.wordprocessingml.document}
  PPT=%w{application/vnd.ms-powerpoint}
  PDF=%w{application/pdf}
  IMAGE=%w{image/gif image/jpeg image/png}
  TEXT=%w{text/plain}
  CSV=%w{text/x-comma-separated-values}
  XML=%w{text/xml}
  
  def test_recognised
    supported_types=MISC+EXCEL+EXCELX+DOC+DOCX+PPT+PDF+IMAGE+TEXT+CSV+XML
    supported_types.each do |type|
      assert_not_equal "Unknown file type", mime_nice_name(type),"Didn't recognise mime type #{type}"
    end
  end

  def test_mimes_for_extension
    mime_types = mime_types_for_extension("xls")
    EXCEL.each do |type|
      assert mime_types.include?(type)
    end

    EXCELX.each do |type|
      assert !mime_types.include?(type)
    end

    assert !mime_types.include?(nil)
  end

  def test_common_types
    EXCEL.each do |type|
      assert_equal "xls",mime_extension(type)
      assert_equal "Spreadsheet",mime_nice_name(type)
      assert_equal icon_filename_for_key("xls_file"),mime_icon_url(type)
    end 
    
    EXCELX.each do |type|
      assert_equal "xlsx",mime_extension(type)
      assert_equal "Spreadsheet",mime_nice_name(type)
      assert_equal icon_filename_for_key("xls_file"),mime_icon_url(type)
    end 
    
    DOC.each do |type|
      assert_equal "doc",mime_extension(type)
      assert_equal "Word document",mime_nice_name(type)
      assert_equal icon_filename_for_key("doc_file"),mime_icon_url(type)
    end 
    
    DOCX.each do |type|
      assert_equal "docx",mime_extension(type)
      assert_equal "Word document",mime_nice_name(type)
      assert_equal icon_filename_for_key("doc_file"),mime_icon_url(type)
    end 
    
    PPT.each do |type|
      assert_equal "ppt",mime_extension(type)
      assert_equal "PowerPoint presentation",mime_nice_name(type)
      assert_equal icon_filename_for_key("ppt_file"),mime_icon_url(type)
    end 
    
    PDF.each do |type|
      assert_equal "pdf",mime_extension(type)
      assert_equal "PDF document",mime_nice_name(type)
      assert_equal icon_filename_for_key("pdf_file"),mime_icon_url(type)
    end 
    
    TEXT.each do |type|
      assert_equal "txt",mime_extension(type)
      assert_equal "Plain text file",mime_nice_name(type)
      assert_equal icon_filename_for_key("txt_file"),mime_icon_url(type)
    end
    
    CSV.each do |type|
      assert_equal "csv",mime_extension(type)
      assert_equal "Comma-seperated-values file",mime_nice_name(type)
      assert_equal icon_filename_for_key("misc_file"),mime_icon_url(type)
    end
    
    XML.each do |type|
      assert_equal "xml",mime_extension(type)
      assert_equal "XML document",mime_nice_name(type)
      assert_equal icon_filename_for_key("xml_file"),mime_icon_url(type)
    end
  end
  
  def test_not_recognised
    assert_equal "Unknown file type", mime_find("application/foobar-zoo-fish-squirrel")[:name]
  end
  
end