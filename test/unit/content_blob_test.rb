require 'test_helper'
require 'docsplit'
require 'seek/download_handling/http_streamer' # Needed to load exceptions that are tested later

class ContentBlobTest < ActiveSupport::TestCase

  fixtures :content_blobs

  test 'search terms' do
    blob = ContentBlob.new
    blob.url = "http://fish.com"
    assert_includes blob.search_terms, 'fish'
    assert_includes blob.search_terms, 'http://fish.com'
    refute_includes blob.search_terms, 'http'
    refute_includes blob.search_terms, 'com'

    blob = Factory(:rightfield_content_blob)
    assert_includes blob.search_terms, 'rightfield.xls'
    assert_includes blob.search_terms, 'xls'

  end


  test 'md5sum_on_demand' do
    blob=Factory :rightfield_content_blob
    assert_not_nil blob.md5sum
    assert_equal "01788bca93265d80e8127ca0039bb69b",blob.md5sum
  end

  test 'sha1 sum on demand' do
    blob=Factory :rightfield_content_blob
    assert_not_nil blob.sha1sum
    assert_equal "ffd634ac7564083ab7b66bc3eb2053cbc3d608f5",blob.sha1sum
  end

  test "detects it is a webpage" do
    as_not_virtualliver do
      mock_remote_file "#{Rails.root}/test/fixtures/files/html_file.html","http://webpage.com",{'Content-Type' => 'text/html'}
      blob = ContentBlob.create :url=>"http://webpage.com",:original_filename=>nil,:content_type=>nil, :external_link => true
      assert blob.is_webpage?
      assert_equal "text/html",blob.content_type
    end
  end

  test "detectes webpage if content-type includes charset info" do
    as_not_virtualliver do
      mock_remote_file "#{Rails.root}/test/fixtures/files/html_file.html","http://webpage.com",{'Content-Type' => 'text/html; charset=ascii'}
      blob = ContentBlob.create :url=>"http://webpage.com",:original_filename=>nil,:content_type=>nil, :external_link => true
      assert blob.is_webpage?
      assert_equal "text/html",blob.content_type
    end
  end

  test "only overrides url content-type if not already known or url points to html" do
    as_not_virtualliver do
      mock_remote_file "#{Rails.root}/test/fixtures/files/html_file.html","http://webpage.com",{'Content-Type' => 'text/html'}
      mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png","http://webpage.com/piccy.png",{'Content-Type' => 'image/png'}

      blob = ContentBlob.create :url=>"http://webpage.com",:original_filename=>nil,:content_type=>nil, :external_link => true
      assert_equal "text/html",blob.content_type

      blob = ContentBlob.create :url=>"http://webpage.com",:original_filename=>nil,:content_type=>"application/pdf", :external_link => true
      assert_equal "text/html",blob.content_type

      blob = ContentBlob.create :url=>"http://webpage.com/piccy.png",:original_filename=>nil,:content_type=>nil
      assert_equal "image/png",blob.content_type

      blob = ContentBlob.create :url=>"http://webpage.com/piccy.png",:original_filename=>nil,:content_type=>"application/x-download"
      assert_equal "image/png",blob.content_type

      blob = ContentBlob.create :url=>"http://webpage.com/piccy.png",:original_filename=>nil,:content_type=>"application/pdf"
      assert_equal "application/pdf",blob.content_type
    end
  end

  test "detects it isn't a webpage" do
    as_not_virtualliver do
      mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png","http://webpage.com/piccy.png",{'Content-Type' => 'image/png'}
      blob = ContentBlob.create :url=>"http://webpage.com/piccy.png",:original_filename=>nil,:content_type=>nil
      assert !blob.is_webpage?
      assert_equal "image/png",blob.content_type
    end
  end

  test "handles an unavailable url when checking for a webpage" do
    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png","http://webpage.com/piccy.png",{'Content-Type' => 'image/png'},500
    blob = ContentBlob.create :url=>"http://webpage.com/piccy.png",:original_filename=>nil,:content_type=>nil
    assert !blob.is_webpage?
  end

  test "content type for url type with binary doesn't try read file" do
    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png","http://webpage.com/binary-file",{'Content-Type' => 'application/octet-stream'},500
    blob = ContentBlob.create :url=>"http://webpage.com/binary-file",:original_filename=>nil,:content_type=>'application/octet-stream'
    assert_equal 'application/octet-stream',blob.content_type
  end

  def test_cache_key
    blob=Factory :rightfield_content_blob
    assert_equal "content_blobs/#{blob.id}-ffd634ac7564083ab7b66bc3eb2053cbc3d608f5",blob.cache_key
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
    blob=ContentBlob.new(:data=>pic.data_io_object.read,:original_filename=>"piccy.jpg")
    blob.save!
    assert_not_nil blob.filepath
    data=nil
    File.open(blob.filepath,"rb") do |f|
      data=f.read
    end
    assert_not_nil data
    assert_equal data_for_test('file_picture.png'),data
  end


  #checks that the data is assigned through the new method, stored to a file, and not written to the old data_old field
  def test_data_assignment
    pic=content_blobs(:picture_blob)
    pic.save! #to trigger callback to save to file
    blob=ContentBlob.new(:data=>pic.data_io_object.read,:original_filename=>"piccy.jpg")
    blob.save!
    blob=ContentBlob.find(blob.id)
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
    pic.data = data_for_test("little_file.txt")
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
    blob=ContentBlob.new(:data=>pic.data_io_object.read,:original_filename=>"piccy.jpg")
    blob.save!
    assert_not_nil blob.uuid
    assert_not_nil ContentBlob.find(blob.id).uuid
  end

  def data_for_test filename
    file = "#{Rails.root}/test/fixtures/files/#{filename}"
    return File.open(file,"rb").read
  end

  def test_tmp_io_object
    io_object = Tempfile.new('tmp_io_object_test')
    io_object.write("blah blah\nmonkey_business")

    blob=ContentBlob.new(:tmp_io_object=>io_object,:original_filename=>"monkey.txt")
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
    blob=ContentBlob.new(:tmp_io_object=>io_object,:original_filename=>"frog.txt")
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

  test "validates by content blob or url" do
    blob = ContentBlob.new
    refute blob.valid?
    blob.original_filename="fish"
    assert blob.valid?
    blob.original_filename=nil
    blob.url="http://google.com"
    assert blob.valid?
  end

  def test_data_io
    io_object = StringIO.new("frog")
    blob=ContentBlob.new(:tmp_io_object=>io_object,:original_filename=>"frog.txt")
    blob.save!
    blob.reload
    assert_equal "frog",blob.data_io_object.read

    f= Tempfile.new("seek-data-io-test")
    f << "fish"
    f.close

    io_object = File.new(f.path,"r")
    blob=ContentBlob.new(:tmp_io_object=>io_object,:original_filename=>"seek-data-io-test")
    blob.save!
    blob.reload
    io_object.rewind
    assert_equal io_object.read,blob.data_io_object.read

    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png","http://www.webpage.com/image.png"
    blob=ContentBlob.new(:url=>"http://www.webpage.com/image.png")
    blob.save!
    blob.reload
    assert_nil blob.data_io_object

    blob=ContentBlob.new :original_filename=>"nil"
    assert_nil blob.data_io_object
    blob.save!
    assert_nil blob.data_io_object
  end

  def test_filesize
    cb = Factory :content_blob, :data=>"z"
    assert_equal 1, cb.file_size
    File.delete(cb.filepath)
    assert_equal 1, cb.file_size
    cb = Factory :rightfield_content_blob
    assert_not_nil cb.file_size
    assert_equal 9216,cb.file_size
  end

  def test_exception_when_both_data_and_io_object
    io_object = StringIO.new("frog")
    blob=ContentBlob.new(:tmp_io_object=>io_object,:data=>"snake",:original_filename=>"snake.txt")
    assert_raise Exception do
      blob.save
    end
  end

  test 'storage_directory and filepath' do
    content_blob = Factory(:content_blob)
    storage_directory = content_blob.data_storage_directory
    converted_storage_directory = content_blob.converted_storage_directory
    assert_equal  "#{Rails.root}/tmp/testing-filestore/assets", storage_directory
    assert_equal  "#{Rails.root}/tmp/testing-filestore/tmp/converted", converted_storage_directory
    assert_equal (storage_directory + '/' + content_blob.uuid + '.dat'), content_blob.filepath
    assert_equal (converted_storage_directory + '/' + content_blob.uuid + '.pdf'), content_blob.filepath('pdf')
    assert_equal (converted_storage_directory + '/' + content_blob.uuid + '.txt'), content_blob.filepath('txt')
  end

  test 'file_exists?' do
    #specify uuid here to avoid repeating uuid of other content_blob when running the whole test file
    content_blob = Factory(:content_blob, :uuid => '1111')
    assert content_blob.file_exists?
    content_blob = Factory(:content_blob, :uuid => '2222', :data=>nil)
    assert !content_blob.file_exists?
  end

  test "human content type" do
    content_blob = Factory(:docx_content_blob)
    assert_equal "Word document",content_blob.human_content_type

    content_blob = Factory(:content_blob, :content_type => "application/msexcel")
    assert_equal "Spreadsheet",content_blob.human_content_type

    content_blob = Factory.create(:pdf_content_blob, :content_type => "application/pdf")
    assert_equal "PDF document",content_blob.human_content_type

    content_blob = Factory(:content_blob, :content_type => "text/html")
    assert_equal "HTML document",content_blob.human_content_type

    content_blob = Factory(:content_blob, :content_type => "application/x-download")
    assert_equal "Unknown file type",content_blob.human_content_type

    content_blob = Factory(:content_blob, :content_type => "")
    assert_equal "Unknown file type",content_blob.human_content_type

    content_blob =  Factory(:content_blob)
    assert_equal "Unknown file type",content_blob.human_content_type

    content_blob= Factory(:tiff_content_blob)
    assert_equal "TIFF image",content_blob.human_content_type

  end

  test "mimemagic updates content type on creation if binary" do
    tmp_blob = Factory(:pdf_content_blob) #to get the filepath
    content_blob = ContentBlob.create :data => File.new(tmp_blob.filepath,"rb").read,:original_filename=>"blob",:content_type=>'application/octet-stream'
    assert_equal 'application/pdf',content_blob.content_type
    assert content_blob.is_pdf?
  end

  test "is_binary?" do
    content_blob = Factory(:pdf_content_blob)
    refute content_blob.is_binary?
    content_blob = Factory(:binary_content_blob)
    assert content_blob.is_binary?
  end

  test 'covert_office should doc to pdf and then docslit convert pdf to txt' do
    check_for_soffice
    content_blob = Factory(:doc_content_blob, :uuid => 'doc_1')
    assert File.exists? content_blob.filepath
    pdf_path = content_blob.filepath('pdf')
    FileUtils.rm pdf_path if File.exists? pdf_path
    assert !File.exists?(pdf_path)

    content_blob.convert_to_pdf

    assert File.exists?(pdf_path), "pdf was not created during conversion"

    content_blob.extract_text_from_pdf

    assert File.exists? content_blob.filepath('txt')

    content = File.open(content_blob.filepath('txt'), 'rb').read
    assert content.include?('This is a ms word doc format')
  end

  test 'convert_office should convert docx to pdf and then docsplit convert pdf to txt' do
    check_for_soffice
    content_blob = Factory(:docx_content_blob, :uuid => 'docx_1')
    assert File.exists? content_blob.filepath
    FileUtils.rm content_blob.filepath('pdf') if File.exists? content_blob.filepath('pdf')
    assert !File.exists?(content_blob.filepath('pdf'))

    content_blob.convert_to_pdf

    assert File.exists?(content_blob.filepath('pdf')), "pdf was not created during conversion"

    content_blob.extract_text_from_pdf

    assert File.exists? content_blob.filepath('txt')

    content = File.open(content_blob.filepath('txt'), 'rb').read
    assert content.include?('This is a ms word docx format')
  end

  test 'convert_office should convert odt to pdf and then docsplit converts pdf to txt' do
    check_for_soffice
    content_blob = Factory(:odt_content_blob, :uuid => 'odt_1')
    assert File.exists? content_blob.filepath
    FileUtils.rm content_blob.filepath('pdf') if File.exists? content_blob.filepath('pdf')
    assert !File.exists?(content_blob.filepath('pdf'))

    content_blob.convert_to_pdf

    assert File.exists?(content_blob.filepath('pdf')), "pdf was not created during conversion"

    content_blob.extract_text_from_pdf

    assert File.exists? content_blob.filepath('txt')

    content = File.open(content_blob.filepath('txt'), 'rb').read
    assert content.include?('This is an open office word odt format')
  end

  test 'convert_office should convert ppt to pdf and then docsplit converts pdf to txt' do
    check_for_soffice
    content_blob = Factory(:ppt_content_blob, :uuid => 'ppt_1')
    assert File.exists? content_blob.filepath
    FileUtils.rm content_blob.filepath('pdf') if File.exists? content_blob.filepath('pdf')
    assert !File.exists?(content_blob.filepath('pdf'))

    content_blob.convert_to_pdf

    assert File.exists?(content_blob.filepath('pdf')), "pdf was not created during conversion"

    content_blob.extract_text_from_pdf

    assert File.exists? content_blob.filepath('txt')

    content = File.open(content_blob.filepath('txt'), 'rb').read
    assert content.include?('This is a ms power point ppt format')
  end

  test 'convert_office should convert pptx to pdf and then docsplit converts pdf to txt' do
    check_for_soffice
    content_blob = Factory(:pptx_content_blob, :uuid => 'pptx_1')
    assert File.exists? content_blob.filepath
    FileUtils.rm content_blob.filepath('pdf') if File.exists? content_blob.filepath('pdf')
    assert !File.exists?(content_blob.filepath('pdf'))

    content_blob.convert_to_pdf

    assert File.exists?(content_blob.filepath('pdf')), "pdf was not created during conversion"

    content_blob.extract_text_from_pdf

    assert File.exists? content_blob.filepath('txt')

    content = File.open(content_blob.filepath('txt'), 'rb').read
    assert content.include?('This is a ms power point pptx format')
  end

  test 'convert_office should convert odp to pdf and then docsplit converts pdf to txt' do
    check_for_soffice
    content_blob = Factory(:odp_content_blob, :uuid => 'odp_1')
    assert File.exists? content_blob.filepath
    FileUtils.rm content_blob.filepath('pdf') if File.exists? content_blob.filepath('pdf')
    assert !File.exists?(content_blob.filepath('pdf'))

    content_blob.convert_to_pdf

    assert File.exists?(content_blob.filepath('pdf')), "pdf was not created during conversion"

    content_blob.extract_text_from_pdf

    assert File.exists? content_blob.filepath('txt')

    content = File.open(content_blob.filepath('txt'), 'rb').read
    assert content.include?('This is an open office power point odp format')
  end

  test 'convert_office should convert rtf to pdf and then docsplit converts pdf to txt' do
    check_for_soffice
    content_blob = Factory(:rtf_content_blob, :uuid => 'rtf_1')
    assert File.exists? content_blob.filepath
    FileUtils.rm content_blob.filepath('pdf') if File.exists? content_blob.filepath('pdf')
    assert !File.exists?(content_blob.filepath('pdf'))

    content_blob.convert_to_pdf

    assert File.exists?(content_blob.filepath('pdf')), "pdf was not created during conversion"

    content_blob.extract_text_from_pdf

    assert File.exists? content_blob.filepath('txt')

    content = File.open(content_blob.filepath('txt'), 'rb').read
    assert content.include?('This is a rtf format')
  end

  test 'convert_office should convert txt to pdf' do
    check_for_soffice
    content_blob = Factory(:txt_content_blob, :uuid => 'txt_1')
    assert File.exists? content_blob.filepath
    FileUtils.rm content_blob.filepath('pdf') if File.exists? content_blob.filepath('pdf')
    assert !File.exists?(content_blob.filepath('pdf'))

    content_blob.convert_to_pdf

    assert File.exists?(content_blob.filepath('pdf')), "pdf was not created during conversion"
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
    viewable_formats << "text/csv"
    viewable_formats << "text/x-comma-separated-values"
    viewable_formats << "text/tab-separated-values"
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

  test 'content should not be viewable when pdf_conversion is disabled' do
    tmp = Seek::Config.pdf_conversion_enabled
    Seek::Config.pdf_conversion_enabled = false

    viewable_formats= %w[application/msword]
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
        assert !cb_with_content_viewable_format.is_content_viewable?
      end
    end

    pdf_content_blob = Factory(:content_blob, :content_type=>'application/pdf', :asset => Factory(:sop), :data => File.new("#{Rails.root}/test/fixtures/files/a_pdf_file.pdf","rb").read)
    User.with_current_user pdf_content_blob.asset.contributor do
      assert pdf_content_blob.is_content_viewable?
    end

    Seek::Config.pdf_conversion_enabled = tmp
  end

  test 'filter_text_content' do
    check_for_soffice
    ms_word_sop_cb = Factory(:doc_content_blob)
    content = "test \n content \f only"
    filtered_content = ms_word_sop_cb.send(:filter_text_content,content)
    assert !filtered_content.include?('\n')
    assert !filtered_content.include?('\f')
  end

  test 'pdf_contents_for_search for a doc file' do
    check_for_soffice
    ms_word_sop_content_blob = Factory(:doc_content_blob)
    assert ms_word_sop_content_blob.is_pdf_convertable?
    content = ms_word_sop_content_blob.pdf_contents_for_search
    assert_equal ['This is a ms word doc format'], content
  end

  test 'pdf_contents_for_search for a pdf file' do
    check_for_soffice
    pdf_content_blob = Factory(:pdf_content_blob)
    content = pdf_content_blob.pdf_contents_for_search
    assert_equal ['This is a pdf format'], content
  end

  test 'calculates file size' do
    blob = Factory(:pdf_content_blob)
    assert_equal 8827, blob.file_size
  end

  test 'updates file size' do
    blob = Factory(:pdf_content_blob)
    blob.data = '123456'
    blob.save
    assert_equal 6, blob.file_size
  end

  test 'calculates file size for remote content' do
    stub_request(:head, "http://www.abc.com").to_return(:headers => {:content_length => 500, :content_type => 'text/plain'}, :status => 200)
    blob = Factory(:url_content_blob)
    assert_equal 500, blob.file_size
  end

  test 'can retrieve remote content' do
    stub_request(:head, "http://www.abc.com").to_return(
        :headers => {:content_length => nil, :content_type => 'text/plain'}, :status => 200)
    stub_request(:get, "http://www.abc.com").to_return(:body => 'abcdefghij'*500,
                                                       :headers => {:content_type => 'text/plain'}, :status => 200)

    blob = Factory(:url_content_blob)
    assert !blob.file_exists?
    assert_equal nil, blob.file_size

    blob.retrieve
    assert blob.file_exists?
    assert_equal 5000, blob.file_size
  end

  test "won't retrieve remote content over hard limit" do
    # Web server lies about content length:
    stub_request(:head, 'http://www.abc.com').to_return(
        :headers => {:content_length => 500, :content_type => 'text/plain'}, :status => 200)
    # Size is actually 6kb:
    stub_request(:get, 'http://www.abc.com').to_return(:body => 'abcdefghij'*600,
                                                       :headers => {:content_type => 'text/plain'}, :status => 200)

    blob = Factory(:url_content_blob)
    assert !blob.file_exists?
    assert_equal 500, blob.file_size

    assert_raise Seek::DownloadHandling::SizeLimitExceededException do
      blob.retrieve
    end
    assert !blob.file_exists?
  end

  test "won't endlessly follow redirects when downloading remote content" do
    stub_request(:head, 'http://www.abc.com').to_return(
        :headers => {:content_length => 500, :content_type => 'text/plain'}, :status => 200)
    # Infinitely redirects
    stub_request(:get, 'http://www.abc.com').to_return(:headers => {:location => 'http://www.abc.com'}, :status => 302)

    blob = Factory(:url_content_blob)
    assert !blob.file_exists?
    assert_equal 500, blob.file_size

    assert_raise Seek::DownloadHandling::RedirectLimitExceededException do
      blob.retrieve
    end
    assert !blob.file_exists?
  end

  test "raises exception on bad response code when downloading remote content" do
    stub_request(:head, 'http://www.abc.com').to_return(
        :headers => {:content_length => 500, :content_type => 'text/plain'}, :status => 200)
    stub_request(:get, 'http://www.abc.com').to_return(:status => 404)

    blob = Factory(:url_content_blob)
    assert !blob.file_exists?
    assert_equal 500, blob.file_size

    assert_raise Seek::DownloadHandling::BadResponseCodeException do
      blob.retrieve
    end
    assert !blob.file_exists?
  end

  test "handles relative redirects when downloading remote content" do
    stub_request(:head, 'http://www.abc.com').to_return(:headers => {:location => '/xyz'}, :status => 302)
    stub_request(:get, 'http://www.abc.com').to_return(:headers => {:location => '/xyz'}, :status => 302)
    stub_request(:head, "http://www.abc.com/xyz").to_return(
        :headers => {:content_length => nil, :content_type => 'text/plain'}, :status => 200)
    stub_request(:get, "http://www.abc.com/xyz").to_return(:body => 'abcdefghij'*500,
                                                       :headers => {:content_type => 'text/plain'}, :status => 200)

    blob = Factory(:url_content_blob)
    assert !blob.file_exists?
    assert_equal nil, blob.file_size

    blob.retrieve
    assert blob.file_exists?
    assert_equal 5000, blob.file_size
  end

  test "handles absolute redirects when downloading remote content" do
    stub_request(:head, 'http://www.abc.com').to_return(:headers => {:location => 'http://www.abc.com/xyz'}, :status => 302)
    stub_request(:get, 'http://www.abc.com').to_return(:headers => {:location => 'http://www.abc.com/xyz'}, :status => 302)
    stub_request(:head, "http://www.abc.com/xyz").to_return(
        :headers => {:content_length => nil, :content_type => 'text/plain'}, :status => 200)
    stub_request(:get, "http://www.abc.com/xyz").to_return(:body => 'abcdefghij'*500,
                                                           :headers => {:content_type => 'text/plain'}, :status => 200)

    blob = Factory(:url_content_blob)
    assert !blob.file_exists?
    assert_equal nil, blob.file_size

    blob.retrieve
    assert blob.file_exists?
    assert_equal 5000, blob.file_size
  end

  test "handles mixed redirects when downloading remote content" do
    stub_request(:head, 'http://www.abc.com').to_return(:headers => {:location => 'http://www.xyz.com'}, :status => 302)
    stub_request(:get, 'http://www.abc.com').to_return(:headers => {:location => 'http://www.xyz.com'}, :status => 302)
    stub_request(:head, 'http://www.xyz.com').to_return(:headers => {:location => '/xyz'}, :status => 302)
    stub_request(:get, 'http://www.xyz.com').to_return(:headers => {:location => '/xyz'}, :status => 302)
    stub_request(:head, "http://www.xyz.com/xyz").to_return(
        :headers => {:content_length => nil, :content_type => 'text/plain'}, :status => 200)
    stub_request(:get, "http://www.xyz.com/xyz").to_return(:body => 'abcdefghij'*500,
                                                           :headers => {:content_type => 'text/plain'}, :status => 200)

    blob = Factory(:url_content_blob)
    assert !blob.file_exists?
    assert_equal nil, blob.file_size

    blob.retrieve
    assert blob.file_exists?
    assert_equal 5000, blob.file_size
  end

  test 'is_text?' do
    assert Factory(:txt_content_blob).is_text?
    assert Factory(:csv_content_blob).is_text?
    assert Factory(:tsv_content_blob).is_text?
    assert Factory(:teusink_model_content_blob).is_text?
    assert Factory(:json_content_blob).is_text?

    refute Factory(:ppt_content_blob).is_text?
    refute Factory(:binary_content_blob).is_text?
  end

end
