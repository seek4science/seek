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

  test 'docsplit should convert ms word doc to pdf; and then pdf to txt' do
    #convert ms word to pdf
    #then convert pdf file to txt file
    ms_word_content_blob = Factory(:doc_content_blob)
    directory_storage_path = ms_word_content_blob.directory_storage_path
    Docsplit.extract_pdf(ms_word_content_blob.filepath, :output => directory_storage_path)
    Docsplit.extract_text(ms_word_content_blob.filepath('pdf'), :output => directory_storage_path)
    assert ms_word_content_blob.file_exists?(ms_word_content_blob.filepath)
    assert ms_word_content_blob.file_exists?(ms_word_content_blob.filepath('pdf'))
    assert ms_word_content_blob.file_exists?(ms_word_content_blob.filepath('txt'))

    ms_word_file_content = File.open(ms_word_content_blob.filepath('txt'), 'rb').read
    assert ms_word_file_content.include?('This is a ms word doc format')
  end

  test 'docsplit should convert ms word docx to pdf; and then pdf to txt' do
    #convert ms word to pdf
    #then convert pdf file to txt file
    ms_word_content_blob = Factory(:docx_content_blob)
    directory_storage_path = ms_word_content_blob.directory_storage_path
    Docsplit.extract_pdf(ms_word_content_blob.filepath, :output => directory_storage_path)
    Docsplit.extract_text(ms_word_content_blob.filepath('pdf'), :output => directory_storage_path)
    assert ms_word_content_blob.file_exists?(ms_word_content_blob.filepath)
    assert ms_word_content_blob.file_exists?(ms_word_content_blob.filepath('pdf'))
    assert ms_word_content_blob.file_exists?(ms_word_content_blob.filepath('txt'))

    ms_word_file_content = File.open(ms_word_content_blob.filepath('txt'), 'rb').read
    assert ms_word_file_content.include?('This is a ms word docx format')
  end

  test 'docsplit should convert open office word odt to pdf; and then pdf to txt' do
    #convert open office word to pdf
    #then convert pdf file to txt file
    openoffice_word_content_blob = Factory(:odt_content_blob)
    directory_storage_path = openoffice_word_content_blob.directory_storage_path
    Docsplit.extract_pdf(openoffice_word_content_blob.filepath, :output => directory_storage_path)
    Docsplit.extract_text(openoffice_word_content_blob.filepath('pdf'), :output => directory_storage_path)
    assert openoffice_word_content_blob.file_exists?(openoffice_word_content_blob.filepath)
    assert openoffice_word_content_blob.file_exists?(openoffice_word_content_blob.filepath('pdf'))
    assert openoffice_word_content_blob.file_exists?(openoffice_word_content_blob.filepath('txt'))

    ms_word_file_content = File.open(openoffice_word_content_blob.filepath('txt'), 'rb').read
    assert ms_word_file_content.include?('This is an open office word odt format')
  end

  test 'docsplit should convert open office word fodt to pdf; and then pdf to txt' do
    #convert open office word to pdf
    #then convert pdf file to txt file
    openoffice_word_content_blob = Factory(:fodt_content_blob)
    directory_storage_path = openoffice_word_content_blob.directory_storage_path
    Docsplit.extract_pdf(openoffice_word_content_blob.filepath, :output => directory_storage_path)
    Docsplit.extract_text(openoffice_word_content_blob.filepath('pdf'), :output => directory_storage_path)
    assert openoffice_word_content_blob.file_exists?(openoffice_word_content_blob.filepath)
    assert openoffice_word_content_blob.file_exists?(openoffice_word_content_blob.filepath('pdf'))
    assert openoffice_word_content_blob.file_exists?(openoffice_word_content_blob.filepath('txt'))

    ms_word_file_content = File.open(openoffice_word_content_blob.filepath('txt'), 'rb').read
    assert ms_word_file_content.include?('This is an open office word fodt format')
  end

  test 'docsplit should convert ms ppt to pdf; and then pdf to txt' do
    #convert ms ppt to pdf
    #then convert pdf file to txt file
    ms_ppt_content_blob = Factory(:ppt_content_blob)
    directory_storage_path = ms_ppt_content_blob.directory_storage_path
    Docsplit.extract_pdf(ms_ppt_content_blob.filepath, :output => directory_storage_path)
    Docsplit.extract_text(ms_ppt_content_blob.filepath('pdf'), :output => directory_storage_path)
    assert ms_ppt_content_blob.file_exists?(ms_ppt_content_blob.filepath)
    assert ms_ppt_content_blob.file_exists?(ms_ppt_content_blob.filepath('pdf'))
    assert ms_ppt_content_blob.file_exists?(ms_ppt_content_blob.filepath('txt'))

    ms_word_file_content = File.open(ms_ppt_content_blob.filepath('txt'), 'rb').read
    assert ms_word_file_content.include?('This is a ms power point ppt format')
  end

  test 'docsplit should convert ms pptx to pdf; and then pdf to txt' do
    #convert ms ppt to pdf
    #then convert pdf file to txt file
    ms_ppt_content_blob = Factory(:pptx_content_blob)
    directory_storage_path = ms_ppt_content_blob.directory_storage_path
    Docsplit.extract_pdf(ms_ppt_content_blob.filepath, :output => directory_storage_path)
    Docsplit.extract_text(ms_ppt_content_blob.filepath('pdf'), :output => directory_storage_path)
    assert ms_ppt_content_blob.file_exists?(ms_ppt_content_blob.filepath)
    assert ms_ppt_content_blob.file_exists?(ms_ppt_content_blob.filepath('pdf'))
    assert ms_ppt_content_blob.file_exists?(ms_ppt_content_blob.filepath('txt'))

    ms_word_file_content = File.open(ms_ppt_content_blob.filepath('txt'), 'rb').read
    assert ms_word_file_content.include?('This is a ms power point pptx format')
  end

  test 'docsplit should convert ms pps to pdf; and then pdf to txt' do
    #convert ms ppt to pdf
    #then convert pdf file to txt file
    ms_ppt_content_blob = Factory(:pps_content_blob)
    directory_storage_path = ms_ppt_content_blob.directory_storage_path
    Docsplit.extract_pdf(ms_ppt_content_blob.filepath, :output => directory_storage_path)
    Docsplit.extract_text(ms_ppt_content_blob.filepath('pdf'), :output => directory_storage_path)
    assert ms_ppt_content_blob.file_exists?(ms_ppt_content_blob.filepath)
    assert ms_ppt_content_blob.file_exists?(ms_ppt_content_blob.filepath('pdf'))
    assert ms_ppt_content_blob.file_exists?(ms_ppt_content_blob.filepath('txt'))

    ms_word_file_content = File.open(ms_ppt_content_blob.filepath('txt'), 'rb').read
    assert ms_word_file_content.include?('This is a ms power point pps format')
  end

  test 'docsplit should convert open office ppt to pdf; and then pdf to txt' do
    #convert open office ppt to pdf
    #then convert pdf file to txt file
    openoffice_ppt_content_blob = Factory(:odp_content_blob)
    directory_storage_path = openoffice_ppt_content_blob.directory_storage_path
    Docsplit.extract_pdf(openoffice_ppt_content_blob.filepath, :output => directory_storage_path)
    Docsplit.extract_text(openoffice_ppt_content_blob.filepath('pdf'), :output => directory_storage_path)
    assert openoffice_ppt_content_blob.file_exists?(openoffice_ppt_content_blob.filepath)
    assert openoffice_ppt_content_blob.file_exists?(openoffice_ppt_content_blob.filepath('pdf'))
    assert openoffice_ppt_content_blob.file_exists?(openoffice_ppt_content_blob.filepath('txt'))

    ms_word_file_content = File.open(openoffice_ppt_content_blob.filepath('txt'), 'rb').read
    assert ms_word_file_content.include?('This is an open office power point odp format')
  end

  test 'docsplit should convert open office fodp to pdf; and then pdf to txt' do
    #convert open office ppt to pdf
    #then convert pdf file to txt file
    openoffice_ppt_content_blob = Factory(:fodp_content_blob)
    directory_storage_path = openoffice_ppt_content_blob.directory_storage_path
    Docsplit.extract_pdf(openoffice_ppt_content_blob.filepath, :output => directory_storage_path)
    Docsplit.extract_text(openoffice_ppt_content_blob.filepath('pdf'), :output => directory_storage_path)
    assert openoffice_ppt_content_blob.file_exists?(openoffice_ppt_content_blob.filepath)
    assert openoffice_ppt_content_blob.file_exists?(openoffice_ppt_content_blob.filepath('pdf'))
    assert openoffice_ppt_content_blob.file_exists?(openoffice_ppt_content_blob.filepath('txt'))

    ms_word_file_content = File.open(openoffice_ppt_content_blob.filepath('txt'), 'rb').read
    assert ms_word_file_content.include?('This is an open office power point fodp format')
  end

  test 'docsplit should convert open office rtf to pdf; and then pdf to txt' do
    #convert open office ppt to pdf
    #then convert pdf file to txt file
    openoffice_ppt_content_blob = Factory(:rtf_content_blob)
    directory_storage_path = openoffice_ppt_content_blob.directory_storage_path
    Docsplit.extract_pdf(openoffice_ppt_content_blob.filepath, :output => directory_storage_path)
    Docsplit.extract_text(openoffice_ppt_content_blob.filepath('pdf'), :output => directory_storage_path)
    assert openoffice_ppt_content_blob.file_exists?(openoffice_ppt_content_blob.filepath)
    assert openoffice_ppt_content_blob.file_exists?(openoffice_ppt_content_blob.filepath('pdf'))
    assert openoffice_ppt_content_blob.file_exists?(openoffice_ppt_content_blob.filepath('txt'))

    ms_word_file_content = File.open(openoffice_ppt_content_blob.filepath('txt'), 'rb').read
    assert ms_word_file_content.include?('This is a rtf format')
  end

  test 'docsplit should not convert a pdf file to pdf' do
    #specify uuid here to avoid repeating uuid of other content_blob when running the whole test file
    pdf_content_blob = Factory(:pdf_content_blob, :uuid => '2222')
    assert !pdf_content_blob.file_exists?(pdf_content_blob.filepath('pdf'))
    directory_storage_path = pdf_content_blob.directory_storage_path
    begin
      Docsplit.extract_pdf(pdf_content_blob.filepath, :output => directory_storage_path)
    rescue
    end
    assert pdf_content_blob.file_exists?(pdf_content_blob.filepath)
    assert !pdf_content_blob.file_exists?(pdf_content_blob.filepath('pdf'))
  end
end
