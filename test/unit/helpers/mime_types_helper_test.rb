require 'test_helper'

class MimeTypesHelperTest < ActionView::TestCase
  include MimeTypesHelper
  include ImagesHelper

  MISC = %w(application/octet-stream application/zip text/x-objcsrc)
  EXCEL = %w(application/excel application/vnd.excel application/vnd.ms-excel)
  EXCELX = %w(application/vnd.openxmlformats-officedocument.spreadsheetml.sheet)
  EXCELM = %w(application/vnd.ms-excel.sheet.macroEnabled.12)
  DOC = %w(application/msword)
  DOCX = %w(application/vnd.openxmlformats-officedocument.wordprocessingml.document)
  PPT = %w(application/vnd.ms-powerpoint)
  PDF = %w(application/pdf)
  IMAGE = %w(image/gif image/jpeg image/png image/bmp image/svg+xml)
  TEXT = %w(text/plain)
  CSV = %w(text/x-comma-separated-values)
  XML = %w(text/xml)
  ODP = %w(application/vnd.oasis.opendocument.presentation)
  FODP = %w(application/vnd.oasis.opendocument.presentation-flat-xml)
  ODT = %w(application/vnd.oasis.opendocument.text)
  FODT = %w(application/vnd.oasis.opendocument.text-flat-xml)
  RTF = %w(application/rtf)
  HTML = %w(text/html)
  SBML = %w(application/sbml+xml)
  MATLAB = %w(application/matlab)
  MP4_IN_MIME_MAGIC = %w(video/mp4)

  def test_recognised
    supported_types = MISC + EXCEL + EXCELX + EXCELM + DOC + DOCX + PPT + PDF + IMAGE + TEXT + CSV + XML + ODP + FODP + ODT + FODT + RTF + HTML + MATLAB
    supported_types.each do |type|
      assert_not_equal 'Unknown file type', mime_nice_name(type), "Didn't recognise mime type #{type}"
    end
  end

  def test_mimes_for_extension
    mime_types = mime_types_for_extension('xls')
    EXCEL.each do |type|
      assert mime_types.include?(type)
    end

    EXCELX.each do |type|
      assert !mime_types.include?(type)
    end

    mime_magic_types = mime_types_for_extension('mp4')
    MP4_IN_MIME_MAGIC.each do |type|
      assert mime_magic_types.include? type
    end
    assert !mime_types.include?(nil)
  end

  def test_common_types
    SBML.each do |type|
      assert mime_extensions(type).include?('xml')
      assert_equal 'SBML and XML document', mime_nice_name(type)
      assert_equal icon_filename_for_key('xml_file'), mime_icon_url(type)
    end

    EXCEL.each do |type|
      assert mime_extensions(type).include?('xls')
      assert_equal 'Spreadsheet', mime_nice_name(type)
      assert_equal icon_filename_for_key('xls_file'), mime_icon_url(type)
    end

    EXCELX.each do |type|
      assert mime_extensions(type).include?('xlsx')
      assert_equal 'Spreadsheet', mime_nice_name(type)
      assert_equal icon_filename_for_key('xls_file'), mime_icon_url(type)
    end

    EXCELM.each do |type|
      assert mime_extensions(type).include?('xlsm')
      assert_equal 'Spreadsheet (macro enabled)', mime_nice_name(type)
      assert_equal icon_filename_for_key('xls_file'), mime_icon_url(type)
    end

    DOC.each do |type|
      assert mime_extensions(type).include?('doc')
      assert_equal 'Word document', mime_nice_name(type)
      assert_equal icon_filename_for_key('doc_file'), mime_icon_url(type)
    end

    DOCX.each do |type|
      assert mime_extensions(type).include?('docx')
      assert_equal 'Word document', mime_nice_name(type)
      assert_equal icon_filename_for_key('doc_file'), mime_icon_url(type)
    end

    PPT.each do |type|
      assert mime_extensions(type).include?('ppt')
      assert_equal 'PowerPoint presentation', mime_nice_name(type)
      assert_equal icon_filename_for_key('ppt_file'), mime_icon_url(type)
    end

    PDF.each do |type|
      assert mime_extensions(type).include?('pdf')
      assert_equal 'PDF document', mime_nice_name(type)
      assert_equal icon_filename_for_key('pdf_file'), mime_icon_url(type)
    end

    TEXT.each do |type|
      assert mime_extensions(type).include?('txt')
      assert_equal 'Plain text document', mime_nice_name(type)
      assert_equal icon_filename_for_key('txt_file'), mime_icon_url(type)
    end

    CSV.each do |type|
      assert mime_extensions(type).include?('csv')
      assert_equal 'Comma-separated values document', mime_nice_name(type)
      assert_equal icon_filename_for_key('misc_file'), mime_icon_url(type)
    end

    XML.each do |type|
      assert mime_extensions(type).include?('xml')
      assert_equal 'XML document', mime_nice_name(type)
      assert_equal icon_filename_for_key('xml_file'), mime_icon_url(type)
    end

    ODP.each do |type|
      assert mime_extensions(type).include?('odp')
      assert_equal 'PowerPoint presentation', mime_nice_name(type)
      assert_equal icon_filename_for_key('ppt_file'), mime_icon_url(type)
    end

    FODP.each do |type|
      assert mime_extensions(type).include?('fodp')
      assert_equal 'PowerPoint presentation', mime_nice_name(type)
      assert_equal icon_filename_for_key('ppt_file'), mime_icon_url(type)
    end

    ODT.each do |type|
      assert mime_extensions(type).include?('odt')
      assert_equal 'Word document', mime_nice_name(type)
      assert_equal icon_filename_for_key('doc_file'), mime_icon_url(type)
    end

    FODT.each do |type|
      assert mime_extensions(type).include?('fodt')
      assert_equal 'Word document', mime_nice_name(type)
      assert_equal icon_filename_for_key('doc_file'), mime_icon_url(type)
    end

    RTF.each do |type|
      assert mime_extensions(type).include?('rtf')
      assert_equal 'RTF document', mime_nice_name(type)
      assert_equal icon_filename_for_key('rtf_file'), mime_icon_url(type)
    end

    HTML.each do |type|
      assert mime_extensions(type).include?('html')
      assert_equal 'HTML document', mime_nice_name(type)
      assert_equal icon_filename_for_key('html_file'), mime_icon_url(type)
    end

    MATLAB.each do |type|
      assert mime_extensions(type).include?('m')
      assert mime_extensions(type).include?('mat')
      assert_equal 'Matlab file', mime_nice_name(type)
      assert_equal icon_filename_for_key('misc_file'), mime_icon_url(type)
    end
  end

  def test_recognised_but_no_icon
    assert_equal 'Perl script', mime_find('application/x-perl')[:name]
    assert_equal icon_filename_for_key('misc_file'), mime_icon_url('application/x-perl')
  end

  def test_not_recognised
    assert_equal 'Unknown file type', mime_find('application/foobar-zoo-fish-squirrel')[:name]
  end

  def test_recognise_with_mime_magic
    mime_not_in_seek = MP4_IN_MIME_MAGIC.first
    assert !MIME_MAP[mime_not_in_seek]
    assert mime_magic_map[mime_not_in_seek]
    assert_equal 'MPEG-4 video', mime_magic_map[mime_not_in_seek][:name]

    assert_equal 'MPEG-4 video', mime_nice_name(mime_not_in_seek)
  end
end
