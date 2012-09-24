require 'test_helper'
require 'docsplit'

class ContentBlobTest < ActiveSupport::TestCase

  fixtures :content_blobs

  def test_md5sum_on_demand
    blob=Factory :rightfield_content_blob
    assert_not_nil blob.md5sum
    assert_equal "01788bca93265d80e8127ca0039bb69b",blob.md5sum
  end

  def test_cache_key
    blob=Factory :rightfield_content_blob
    assert_equal "content_blobs/#{blob.id}-01788bca93265d80e8127ca0039bb69b",blob.cache_key
  end

  def test_uuid_doesnt_change
    blob=content_blobs(:picture_blob)
    blob.uuid="zzz"
    assert_equal "zzz",blob.uuid
    blob.save!
    assert_equal "zzz",blob.uuid
  end

  def test_uuid_doesnt_change2
    blob=content_blobs(:picture_blob)
    blob.uuid="zzz"
    blob.save!
    blob=ContentBlob.find(blob.id)
    assert_equal "zzz",blob.uuid
    blob.save!
    blob=ContentBlob.find(blob.id)
    assert_equal "zzz",blob.uuid
  end

  def test_regenerate_uuid
    pic=content_blobs(:picture_blob)
    uuid=pic.uuid
    pic.regenerate_uuid
    assert_not_equal uuid,pic.uuid
  end

  def test_file_dump
    pic=content_blobs(:picture_blob)
    blob=ContentBlob.new(:data=>pic.data_io_object.read)
    blob.save!
    assert_not_nil blob.filepath
    data=nil
    File.open(blob.filepath,"rb") do |f|
      data=f.read
    end
    assert_not_nil data
    assert_equal data_for_test('file_picture.png'),data
  end

#  def test_dumps_file_on_fetch
#    pic=content_blobs(:picture_blob)    
#    pic.regenerate_uuid #makes sure is not there from a previous test    
#    assert !pic.file_exists?
#    assert_equal data_for_test('file_picture.png'),pic.data_io_object.read
#    assert pic.file_exists?
#    assert_equal data_for_test('file_picture.png'),pic.data_io_object.read
#  end

#  def test_file_exists
#    pic=content_blobs(:picture_blob)    
#    pic.regenerate_uuid #makes sure is not there from a previous test
#    assert !pic.file_exists?
#    pic.save!
#    assert pic.file_exists?
#  end

  #checks that the data is assigned through the new method, stored to a file, and not written to the old data_old field
  def test_data_assignment
    pic=content_blobs(:picture_blob)
    pic.save! #to trigger callback to save to file
    blob=ContentBlob.new(:data=>pic.data_io_object.read)
    blob.save!
    blob=ContentBlob.find(blob.id)
    assert_nil blob.data_old
    assert_equal data_for_test('file_picture.png'),blob.data_io_object.read

    assert_not_nil blob.filepath
    data=nil
    File.open(blob.filepath,"rb") do |f|
      data=f.read
    end
    assert_not_nil data
    assert_equal data_for_test('file_picture.png'),data
  end

  #simply checks that get and set data returns the same thing
  def test_data_assignment2
    pic=content_blobs(:picture_blob)
    pic.data=data_for_test("little_file.txt")
    pic.save!
    assert_equal data_for_test("little_file.txt"),pic.data_io_object.read

    #put it back, otherwise other tests fail
    pic.data=data_for_test('file_picture.png')
    pic.save!
  end
#
  def test_will_overwrite_if_data_changes
    pic=content_blobs(:picture_blob)
    pic.save!
    assert_equal data_for_test("file_picture.png"),File.open(pic.filepath,"rb").read
    pic.data=data_for_test("little_file.txt")
    pic.save!
    assert_equal data_for_test("little_file.txt"),File.open(pic.filepath,"rb").read
  end

  def test_uuid
    pic=content_blobs(:picture_blob)
    blob=ContentBlob.new(:data=>pic.data_io_object.read)
    blob.save!
    assert_not_nil blob.uuid
    assert_not_nil ContentBlob.find(blob.id).uuid
  end

  def data_for_test filename
    file = "#{RAILS_ROOT}/test/fixtures/files/#{filename}"
    return File.open(file,"rb").read
  end

  def test_tmp_io_object
    io_object = Tempfile.new('tmp_io_object_test')
    io_object.write("blah blah\nmonkey_business")

    blob=ContentBlob.new(:tmp_io_object=>io_object)
    assert_difference("ContentBlob.count") do
      blob.save!
    end

    blob.reload
    assert_not_nil blob.filepath
    assert File.exists?(blob.filepath)
    data=nil
    File.open(blob.filepath,"rb") do |f|
      data=f.read
    end

    assert_not_nil data
    assert_equal "blah blah\nmonkey_business",data.to_s
  end

  def test_string_io_object
    io_object = StringIO.new("frog")
    blob=ContentBlob.new(:tmp_io_object=>io_object)
    assert_difference("ContentBlob.count") do
      blob.save!
    end

    blob.reload
    assert_not_nil blob.filepath
    assert File.exists?(blob.filepath)
    data=nil
    File.open(blob.filepath,"rb") do |f|
      data=f.read
    end

    assert_not_nil data
    assert_equal "frog",data.to_s
  end

  def test_data_io
    io_object = StringIO.new("frog")
    blob=ContentBlob.new(:tmp_io_object=>io_object)
    blob.save!
    blob.reload
    assert_equal "frog",blob.data_io_object.read

    file_path=File.expand_path(__FILE__) #use the current file
    io_object = File.new(file_path,"r")
    blob=ContentBlob.new(:tmp_io_object=>io_object)
    blob.save!
    blob.reload
    io_object.rewind
    assert_equal io_object.read,blob.data_io_object.read

    blob=ContentBlob.new(:url=>"http://www.sysmo-db.org/images/sysmo-db-logo-grad2.png")
    blob.save!
    blob.reload
    assert_nil blob.data_io_object

    blob=ContentBlob.new
    assert_nil blob.data_io_object
    blob.save!
    assert_nil blob.data_io_object
  end

  def test_filesize
    cb = Factory :content_blob, :data=>"z"
    assert_equal 1, cb.filesize
    File.delete(cb.filepath)
    assert_nil cb.filesize
    cb = Factory :rightfield_content_blob
    assert_not_nil cb.filesize
    assert_equal 9216,cb.filesize
  end

  def test_exception_when_both_data_and_io_object
    io_object = StringIO.new("frog")
    blob=ContentBlob.new(:tmp_io_object=>io_object,:data=>"snake")
    assert_raise Exception do
      blob.save
    end
  end

  test 'directory_storage_path and filepath' do
    content_blob = Factory(:content_blob)
    directory_storage_path = content_blob.directory_storage_path
    assert_equal  "/tmp/seek_content_blobs", directory_storage_path
    assert_equal (directory_storage_path + '/' + content_blob.uuid + '.dat'), content_blob.filepath
    assert_equal (directory_storage_path + '/' + content_blob.uuid + '.pdf'), content_blob.filepath('pdf')
    assert_equal (directory_storage_path + '/' + content_blob.uuid + '.txt'), content_blob.filepath('txt')
  end

  test 'file_exists?' do
    #specify uuid here to avoid repeating uuid of other content_blob when running the whole test file
    content_blob = Factory(:content_blob, :uuid => '1111')
    assert content_blob.file_exists?
    assert content_blob.file_exists?(content_blob.filepath)
    assert !content_blob.file_exists?(content_blob.filepath('pdf'))
    assert !content_blob.file_exists?(content_blob.filepath('txt'))
  end

  test 'covert_office should doc to pdf; and then docslit convert pdf to txt' do
    doc_content_blob = Factory(:doc_content_blob, :uuid => 'doc_1')
    directory_storage_path = doc_content_blob.directory_storage_path
    doc_content_blob.convert_to_pdf
    Docsplit.extract_text(doc_content_blob.filepath('pdf'), :output => directory_storage_path)
    assert doc_content_blob.file_exists?(doc_content_blob.filepath)
    assert doc_content_blob.file_exists?(doc_content_blob.filepath('pdf'))
    assert doc_content_blob.file_exists?(doc_content_blob.filepath('txt'))

    doc_content = File.open(doc_content_blob.filepath('txt'), 'rb').read
    assert doc_content.include?('This is a ms word doc format')
  end

  test 'convert_office should convert docx to pdf; and then docsplit convert pdf to txt' do
    docx_content_blob = Factory(:docx_content_blob, :uuid => 'docx_1')
    directory_storage_path = docx_content_blob.directory_storage_path
    docx_content_blob.convert_to_pdf
    Docsplit.extract_text(docx_content_blob.filepath('pdf'), :output => directory_storage_path)
    assert docx_content_blob.file_exists?(docx_content_blob.filepath)
    assert docx_content_blob.file_exists?(docx_content_blob.filepath('pdf'))
    assert docx_content_blob.file_exists?(docx_content_blob.filepath('txt'))

    docx_content = File.open(docx_content_blob.filepath('txt'), 'rb').read
    assert docx_content.include?('This is a ms word docx format')
  end

  test 'convert_office should convert odt to pdf; and then docsplit converts pdf to txt' do
    odt_content_blob = Factory(:odt_content_blob, :uuid => 'odt_1')
    directory_storage_path = odt_content_blob.directory_storage_path
    odt_content_blob.convert_to_pdf
    Docsplit.extract_text(odt_content_blob.filepath('pdf'), :output => directory_storage_path)
    assert odt_content_blob.file_exists?(odt_content_blob.filepath)
    assert odt_content_blob.file_exists?(odt_content_blob.filepath('pdf'))
    assert odt_content_blob.file_exists?(odt_content_blob.filepath('txt'))

    odt_content = File.open(odt_content_blob.filepath('txt'), 'rb').read
    assert odt_content.include?('This is an open office word odt format')
  end

  test 'convert_office should convert ppt to pdf; and then docsplit converts pdf to txt' do
    ppt_content_blob = Factory(:ppt_content_blob, :uuid => 'ppt_1')
    directory_storage_path = ppt_content_blob.directory_storage_path
    ppt_content_blob.convert_to_pdf
    Docsplit.extract_text(ppt_content_blob.filepath('pdf'), :output => directory_storage_path)
    assert ppt_content_blob.file_exists?(ppt_content_blob.filepath)
    assert ppt_content_blob.file_exists?(ppt_content_blob.filepath('pdf'))
    assert ppt_content_blob.file_exists?(ppt_content_blob.filepath('txt'))

    ppt_content = File.open(ppt_content_blob.filepath('txt'), 'rb').read
    assert ppt_content.include?('This is a ms power point ppt format')
  end

  test 'convert_office should convert pptx to pdf; and then docsplit converts pdf to txt' do
    pptx_content_blob = Factory(:pptx_content_blob, :uuid => 'pptx_1')
    directory_storage_path = pptx_content_blob.directory_storage_path
    pptx_content_blob.convert_to_pdf
    Docsplit.extract_text(pptx_content_blob.filepath('pdf'), :output => directory_storage_path)
    assert pptx_content_blob.file_exists?(pptx_content_blob.filepath)
    assert pptx_content_blob.file_exists?(pptx_content_blob.filepath('pdf'))
    assert pptx_content_blob.file_exists?(pptx_content_blob.filepath('txt'))

    pptx_content = File.open(pptx_content_blob.filepath('txt'), 'rb').read
    assert pptx_content.include?('This is a ms power point pptx format')
  end

  test 'convert_office should convert odp to pdf; and then docsplit converts pdf to txt' do
    odp_content_blob = Factory(:odp_content_blob, :uuid => 'odp_1')
    directory_storage_path = odp_content_blob.directory_storage_path
    odp_content_blob.convert_to_pdf
    Docsplit.extract_text(odp_content_blob.filepath('pdf'), :output => directory_storage_path)
    assert odp_content_blob.file_exists?(odp_content_blob.filepath)
    assert odp_content_blob.file_exists?(odp_content_blob.filepath('pdf'))
    assert odp_content_blob.file_exists?(odp_content_blob.filepath('txt'))

    odp_content = File.open(odp_content_blob.filepath('txt'), 'rb').read
    assert odp_content.include?('This is an open office power point odp format')
  end

  test 'convert_office should convert rtf to pdf; and then docsplit converts pdf to txt' do
    rtf_content_blob = Factory(:rtf_content_blob, :uuid => 'rtf_1')
    directory_storage_path = rtf_content_blob.directory_storage_path
    rtf_content_blob.convert_to_pdf
    Docsplit.extract_text(rtf_content_blob.filepath('pdf'), :output => directory_storage_path)
    assert rtf_content_blob.file_exists?(rtf_content_blob.filepath)
    assert rtf_content_blob.file_exists?(rtf_content_blob.filepath('pdf'))
    assert rtf_content_blob.file_exists?(rtf_content_blob.filepath('txt'))

    rtf_content = File.open(rtf_content_blob.filepath('txt'), 'rb').read
    assert rtf_content.include?('This is a rtf format')
  end

  test 'convert_office should convert txt to pdf' do
    txt_content_blob = Factory(:txt_content_blob, :uuid => 'txt_1')
    txt_content_blob.convert_to_pdf
    assert txt_content_blob.file_exists?(txt_content_blob.filepath)
    assert txt_content_blob.file_exists?(txt_content_blob.filepath('pdf'))
    assert txt_content_blob.file_exists?(txt_content_blob.filepath('txt'))
  end

  test 'is_content_viewable?' do
    viewable_formats= %w[application/pdf]
    viewable_formats << "application/msword"
    viewable_formats << "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    viewable_formats << "application/vnd.ms-powerpoint"
    viewable_formats << "application/vnd.openxmlformats-officedocument.presentationml.presentation"
    viewable_formats << "application/vnd.oasis.opendocument.text"
    viewable_formats << "application/vnd.oasis.opendocument.presentation"
    viewable_formats << "application/rtf"
    viewable_formats << "text/plain"

    viewable_formats.each do |viewable_format|
      cb_with_content_viewable_format = Factory(:content_blob, :content_type=>viewable_format, :asset => Factory(:sop), :data => File.new("#{Rails.root}/test/fixtures/files/a_pdf_file.pdf","rb").read)
      User.with_current_user cb_with_content_viewable_format.asset.contributor do
        assert cb_with_content_viewable_format.is_viewable_format?
        assert cb_with_content_viewable_format.is_content_viewable?
      end
    end
    cb_with_no_viewable_format = Factory(:content_blob, :content_type=>"application/excel", :asset => Factory(:sop), :data => File.new("#{Rails.root}/test/fixtures/files/spreadsheet.xls","rb").read)
    User.with_current_user cb_with_no_viewable_format.asset.contributor do
      assert !cb_with_no_viewable_format.is_viewable_format?
      assert !cb_with_no_viewable_format.is_content_viewable?
    end
  end

  test 'filter_text_content' do
    ms_word_sop_cb = Factory(:doc_content_blob)
    content = "test \n content \f only"
    filtered_content = ms_word_sop_cb.send(:filter_text_content,content)
    assert !filtered_content.include?('\n')
    assert !filtered_content.include?('\f')
  end

  test 'pdf_contents_for_search' do
    ms_word_sop_content_blob = Factory(:doc_content_blob)
    assert ms_word_sop_content_blob.is_pdf_convertable?
    content = ms_word_sop_content_blob.pdf_contents_for_search
    assert_equal 'This is a ms word doc format', content
  end

end
