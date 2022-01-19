require 'test_helper'
require 'docsplit'
require 'seek/download_handling/http_streamer' # Needed to load exceptions that are tested later
require 'minitest/mock'
require 'private_address_check'

class ContentBlobTest < ActiveSupport::TestCase

  include NelsTestHelper

  fixtures :content_blobs

  test 'search terms' do
    blob = ContentBlob.new
    blob.url = 'http://fish.com'
    assert_includes blob.search_terms, 'fish'
    assert_includes blob.search_terms, 'http://fish.com'
    refute_includes blob.search_terms, 'http'
    refute_includes blob.search_terms, 'com'

    blob = Factory(:txt_content_blob)
    assert_includes blob.search_terms, 'txt_test.txt'
    assert_includes blob.search_terms, 'txt'
  end

  test 'max indexable text size' do
    blob = Factory :large_txt_content_blob
    size = blob.file_size
    assert size > 1.megabyte
    assert size < 2.megabyte

    assert blob.is_text?

    with_config_value :max_indexable_text_size, 1 do
      refute blob.is_indexable_text?
    end

    with_config_value :max_indexable_text_size, 2 do
      assert blob.is_indexable_text?
    end

    with_config_value :max_indexable_text_size, '2' do
      assert blob.is_indexable_text?
    end
  end

  test 'md5sum_on_demand' do
    blob = Factory :rightfield_content_blob
    assert_not_nil blob.md5sum
    assert_equal '01788bca93265d80e8127ca0039bb69b', blob.md5sum
  end

  test 'sha1 sum on demand' do
    blob = Factory :rightfield_content_blob
    assert_not_nil blob.sha1sum
    assert_equal 'ffd634ac7564083ab7b66bc3eb2053cbc3d608f5', blob.sha1sum
  end

  test 'detects it is a webpage' do
    as_not_virtualliver do
      mock_remote_file "#{Rails.root}/test/fixtures/files/html_file.html", 'http://webpage.com', 'Content-Type' => 'text/html'
      blob = ContentBlob.create url: 'http://webpage.com', original_filename: nil, content_type: nil, external_link: true
      assert blob.is_webpage?
      assert_equal 'text/html', blob.content_type
    end
  end

  test 'detectes webpage if content-type includes charset info' do
    as_not_virtualliver do
      mock_remote_file "#{Rails.root}/test/fixtures/files/html_file.html", 'http://webpage.com', 'Content-Type' => 'text/html; charset=ascii'
      blob = ContentBlob.create url: 'http://webpage.com', original_filename: nil, content_type: nil, external_link: true
      assert blob.is_webpage?
      assert_equal 'text/html', blob.content_type
    end
  end

  test 'only overrides url content-type if not already known' do
    as_not_virtualliver do
      mock_remote_file "#{Rails.root}/test/fixtures/files/html_file.html", 'http://webpage.com', 'Content-Type' => 'text/html'
      mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://webpage.com/piccy.png', 'Content-Type' => 'image/png'

      blob = ContentBlob.create url: 'http://webpage.com', original_filename: nil, content_type: nil, external_link: true
      assert_equal 'text/html', blob.content_type

      blob = ContentBlob.create url: 'http://webpage.com/piccy.png', original_filename: nil, content_type: nil
      assert_equal 'image/png', blob.content_type

      blob = ContentBlob.create url: 'http://webpage.com/piccy.png', original_filename: nil, content_type: 'application/pdf'
      assert_equal 'application/pdf', blob.content_type
    end
  end

  test "detects it isn't a webpage" do
    as_not_virtualliver do
      mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://webpage.com/piccy.png', 'Content-Type' => 'image/png'
      blob = ContentBlob.create url: 'http://webpage.com/piccy.png', original_filename: nil, content_type: nil
      assert !blob.is_webpage?
      assert_equal 'image/png', blob.content_type
    end
  end

  test 'handles an unavailable url when checking for a webpage' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://webpage.com/piccy.png', { 'Content-Type' => 'image/png' }, 500
    blob = ContentBlob.create url: 'http://webpage.com/piccy.png', original_filename: nil, content_type: nil
    assert !blob.is_webpage?
  end

  test "content type for url type with binary doesn't try read file" do
    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://webpage.com/binary-file', { 'Content-Type' => 'application/octet-stream' }, 500
    blob = ContentBlob.create url: 'http://webpage.com/binary-file', original_filename: nil, content_type: 'application/octet-stream'
    assert_equal 'application/octet-stream', blob.content_type
  end

  def test_cache_key
    blob = Factory :rightfield_content_blob
    assert_equal "content_blobs/#{blob.id}-ffd634ac7564083ab7b66bc3eb2053cbc3d608f5", blob.cache_key
  end

  def test_uuid_doesnt_change
    blob = content_blobs(:picture_blob)
    blob.uuid = 'zzz'
    assert_equal 'zzz', blob.uuid
    blob.save!
    assert_equal 'zzz', blob.uuid
  end

  def test_uuid_doesnt_change2
    blob = content_blobs(:picture_blob)
    blob.uuid = 'zzz'
    blob.save!
    blob = ContentBlob.find(blob.id)
    assert_equal 'zzz', blob.uuid
    blob.save!
    blob = ContentBlob.find(blob.id)
    assert_equal 'zzz', blob.uuid
  end

  def test_regenerate_uuid
    pic = content_blobs(:picture_blob)
    uuid = pic.uuid
    pic.regenerate_uuid
    assert_not_equal uuid, pic.uuid
  end

  def test_file_dump
    blob = ContentBlob.new(data: data_for_test('file_picture.png'), original_filename: 'piccy.jpg')
    blob.save!
    assert_not_nil blob.filepath
    data = nil
    File.open(blob.filepath, 'rb') do |f|
      data = f.read
    end
    assert_not_nil data
    assert_equal data_for_test('file_picture.png'), data
  end

  # checks that the data is assigned through the new method, stored to a file, and not written to the old data_old field
  def test_data_assignment
    blob = ContentBlob.new(data: data_for_test('file_picture.png'), original_filename: 'piccy.jpg')
    blob.save!
    blob = ContentBlob.find(blob.id)
    assert_equal data_for_test('file_picture.png'), blob.data_io_object.read

    assert_not_nil blob.filepath
    data = nil
    File.open(blob.filepath, 'rb') do |f|
      data = f.read
    end
    assert_not_nil data
    assert_equal data_for_test('file_picture.png'), data
  end

  # simply checks that get and set data returns the same thing
  def test_data_assignment2
    pic = Factory(:content_blob, data: data_for_test('file_picture.png'))
    pic.data = data_for_test('little_file.txt')
    pic.save!
    assert_equal data_for_test('little_file.txt'), pic.data_io_object.read

    # put it back, otherwise other tests fail
    pic.data = data_for_test('file_picture.png')
    pic.save!
  end

  #
  def test_will_overwrite_if_data_changes
    pic = Factory(:content_blob, data: data_for_test('file_picture.png'))
    pic.save!
    assert_equal data_for_test('file_picture.png'), File.open(pic.filepath, 'rb').read
    pic.data = data_for_test('little_file.txt')
    pic.save!
    assert_equal data_for_test('little_file.txt'), File.open(pic.filepath, 'rb').read
  end

  def test_uuid
    blob = Factory(:content_blob)
    blob.save!
    assert_not_nil blob.uuid
    assert_equal blob.uuid, ContentBlob.find(blob.id).uuid
  end

  def data_for_test(filename)
    file = "#{Rails.root}/test/fixtures/files/#{filename}"
    File.open(file, 'rb').read
  end

  def test_tmp_io_object
    io_object = Tempfile.new('tmp_io_object_test')
    io_object.write("blah blah\nmonkey_business")

    blob = ContentBlob.new(tmp_io_object: io_object, original_filename: 'monkey.txt')
    assert_difference('ContentBlob.count') do
      blob.save!
    end

    blob.reload
    assert_not_nil blob.filepath
    assert File.exist?(blob.filepath)
    data = nil
    File.open(blob.filepath, 'rb') do |f|
      data = f.read
    end

    assert_not_nil data
    assert_equal "blah blah\nmonkey_business", data.to_s
  end

  def test_string_io_object
    io_object = StringIO.new('frog')
    blob = ContentBlob.new(tmp_io_object: io_object, original_filename: 'frog.txt')
    assert_difference('ContentBlob.count') do
      blob.save!
    end

    blob.reload
    assert_not_nil blob.filepath
    assert File.exist?(blob.filepath)
    data = nil
    File.open(blob.filepath, 'rb') do |f|
      data = f.read
    end

    assert_not_nil data
    assert_equal 'frog', data.to_s
  end

  test 'validates by content blob or url' do
    blob = ContentBlob.new
    refute blob.valid?
    blob.original_filename = 'fish'
    assert blob.valid?
    blob.original_filename = nil
    blob.url = 'http://google.com'
    assert blob.valid?
  end

  def test_data_io
    io_object = StringIO.new('frog')
    blob = ContentBlob.new(tmp_io_object: io_object, original_filename: 'frog.txt')
    blob.save!
    blob.reload
    assert_equal 'frog', blob.data_io_object.read

    f = Tempfile.new('seek-data-io-test')
    f << 'fish'
    f.close

    io_object = File.new(f.path, 'r')
    blob = ContentBlob.new(tmp_io_object: io_object, original_filename: 'seek-data-io-test')
    blob.save!
    blob.reload
    io_object.rewind
    assert_equal io_object.read, blob.data_io_object.read

    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://www.webpage.com/image.png'
    blob = ContentBlob.new(url: 'http://www.webpage.com/image.png')
    blob.save!
    blob.reload
    assert_nil blob.data_io_object

    blob = ContentBlob.new original_filename: 'nil'
    assert_nil blob.data_io_object
    blob.save!
    assert_nil blob.data_io_object
  end

  def test_filesize
    cb = Factory :content_blob, data: 'z'
    assert_equal 1, cb.file_size
    File.delete(cb.filepath)
    assert_equal 1, cb.file_size
    cb = Factory :rightfield_content_blob
    assert_not_nil cb.file_size
    assert_equal 9216, cb.file_size
  end

  def test_exception_when_both_data_and_io_object
    io_object = StringIO.new('frog')
    blob = ContentBlob.new(tmp_io_object: io_object, data: 'snake', original_filename: 'snake.txt')
    assert_raise Exception do
      blob.save
    end
  end

  test 'storage_directory and filepath' do
    content_blob = Factory(:content_blob)
    storage_directory = content_blob.data_storage_directory
    converted_storage_directory = content_blob.converted_storage_directory
    assert_equal "#{Rails.root}/tmp/testing-filestore/assets", storage_directory
    assert_equal "#{Rails.root}/tmp/testing-filestore/converted-assets", converted_storage_directory
    assert_equal (storage_directory + '/' + content_blob.uuid + '.dat'), content_blob.filepath
    assert_equal (converted_storage_directory + '/' + content_blob.uuid + '.pdf'), content_blob.filepath('pdf')
    assert_equal (converted_storage_directory + '/' + content_blob.uuid + '.txt'), content_blob.filepath('txt')
  end

  test 'file_exists?' do
    # specify uuid here to avoid repeating uuid of other content_blob when running the whole test file
    content_blob = Factory(:content_blob, uuid: '1111')
    assert content_blob.file_exists?
    content_blob = Factory(:content_blob, uuid: '2222', data: nil)
    assert !content_blob.file_exists?
  end

  test 'human content type' do
    content_blob = Factory(:docx_content_blob)
    assert_equal 'Word document', content_blob.human_content_type

    content_blob = Factory(:content_blob, content_type: 'application/msexcel')
    assert_equal 'Spreadsheet', content_blob.human_content_type

    content_blob = Factory(:xlsm_content_blob)
    assert_equal 'Spreadsheet (macro enabled)', content_blob.human_content_type

    content_blob = Factory.create(:pdf_content_blob, content_type: 'application/pdf')
    assert_equal 'PDF document', content_blob.human_content_type

    content_blob = Factory(:content_blob, content_type: 'text/html')
    assert_equal 'HTML document', content_blob.human_content_type

    content_blob = Factory(:content_blob, content_type: 'application/x-download')
    assert_equal 'Unknown file type', content_blob.human_content_type

    content_blob = Factory(:content_blob, content_type: '')
    assert_equal 'Unknown file type', content_blob.human_content_type

    content_blob = Factory(:content_blob)
    assert_equal 'Unknown file type', content_blob.human_content_type

    content_blob = Factory(:tiff_content_blob)
    assert_equal 'TIFF image', content_blob.human_content_type
  end

  test 'override mimetype presented, with detected type' do
    blob = Factory.build(:csv_content_blob, content_type:'application/vnd.excel')
    assert_equal 'application/vnd.excel',blob.content_type
    blob.save!
    assert_equal 'text/csv',blob.content_type

    blob = Factory.build(:xlsm_content_blob,content_type:'text/csv')
    assert_equal 'text/csv',blob.content_type
    blob.save!
    assert_equal 'application/vnd.ms-excel.sheet.macroEnabled.12',blob.content_type
  end

  test 'mimemagic updates content type on creation if binary' do
    tmp_blob = Factory(:pdf_content_blob) # to get the filepath
    content_blob = ContentBlob.create data: File.new(tmp_blob.filepath, 'rb').read, original_filename: 'blob', content_type: 'application/octet-stream'
    assert_equal 'application/pdf', content_blob.content_type
    assert content_blob.is_pdf?
  end

  test 'is_binary?' do
    content_blob = Factory(:pdf_content_blob)
    refute content_blob.is_binary?
    content_blob = Factory(:binary_content_blob)
    assert content_blob.is_binary?
  end

  test 'covert_office should doc to pdf and then docslit convert pdf to txt' do
    check_for_soffice
    content_blob = Factory(:doc_content_blob, uuid: 'doc_1')
    assert File.exist? content_blob.filepath
    pdf_path = content_blob.filepath('pdf')
    FileUtils.rm pdf_path if File.exist? pdf_path
    assert !File.exist?(pdf_path)

    content_blob.convert_to_pdf

    assert File.exist?(pdf_path), 'pdf was not created during conversion'

    content_blob.extract_text_from_pdf

    assert File.exist? content_blob.filepath('txt')

    content = File.open(content_blob.filepath('txt'), 'rb').read
    assert content.include?('This is a ms word doc format')
  end

  test 'convert_office should convert docx to pdf and then docsplit convert pdf to txt' do
    check_for_soffice
    content_blob = Factory(:docx_content_blob, uuid: 'docx_1')
    assert File.exist? content_blob.filepath
    FileUtils.rm content_blob.filepath('pdf') if File.exist? content_blob.filepath('pdf')
    assert !File.exist?(content_blob.filepath('pdf'))

    content_blob.convert_to_pdf

    assert File.exist?(content_blob.filepath('pdf')), 'pdf was not created during conversion'

    content_blob.extract_text_from_pdf

    assert File.exist? content_blob.filepath('txt')

    content = File.open(content_blob.filepath('txt'), 'rb').read
    assert content.include?('This is a ms word docx format')
  end

  test 'convert_office should convert odt to pdf and then docsplit converts pdf to txt' do
    check_for_soffice
    content_blob = Factory(:odt_content_blob, uuid: 'odt_1')
    assert File.exist? content_blob.filepath
    FileUtils.rm content_blob.filepath('pdf') if File.exist? content_blob.filepath('pdf')
    assert !File.exist?(content_blob.filepath('pdf'))

    content_blob.convert_to_pdf

    assert File.exist?(content_blob.filepath('pdf')), 'pdf was not created during conversion'

    content_blob.extract_text_from_pdf

    assert File.exist? content_blob.filepath('txt')

    content = File.open(content_blob.filepath('txt'), 'rb').read
    assert content.include?('This is an open office word odt format')
  end

  test 'convert_office should convert ppt to pdf and then docsplit converts pdf to txt' do
    check_for_soffice
    content_blob = Factory(:ppt_content_blob, uuid: 'ppt_1')
    assert File.exist? content_blob.filepath
    FileUtils.rm content_blob.filepath('pdf') if File.exist? content_blob.filepath('pdf')
    assert !File.exist?(content_blob.filepath('pdf'))

    content_blob.convert_to_pdf

    assert File.exist?(content_blob.filepath('pdf')), 'pdf was not created during conversion'

    content_blob.extract_text_from_pdf

    assert File.exist? content_blob.filepath('txt')

    content = File.open(content_blob.filepath('txt'), 'rb').read
    assert content.include?('This is a ms power point ppt format')
  end

  test 'convert_office should convert pptx to pdf and then docsplit converts pdf to txt' do
    check_for_soffice
    content_blob = Factory(:pptx_content_blob, uuid: 'pptx_1')
    assert File.exist? content_blob.filepath
    FileUtils.rm content_blob.filepath('pdf') if File.exist? content_blob.filepath('pdf')
    assert !File.exist?(content_blob.filepath('pdf'))

    content_blob.convert_to_pdf

    assert File.exist?(content_blob.filepath('pdf')), 'pdf was not created during conversion'

    content_blob.extract_text_from_pdf

    assert File.exist? content_blob.filepath('txt')

    content = File.open(content_blob.filepath('txt'), 'rb').read
    assert content.include?('This is a ms power point pptx format')
  end

  test 'convert_office should convert odp to pdf and then docsplit converts pdf to txt' do
    check_for_soffice
    content_blob = Factory(:odp_content_blob, uuid: 'odp_1')
    assert File.exist? content_blob.filepath
    FileUtils.rm content_blob.filepath('pdf') if File.exist? content_blob.filepath('pdf')
    assert !File.exist?(content_blob.filepath('pdf'))

    content_blob.convert_to_pdf

    assert File.exist?(content_blob.filepath('pdf')), 'pdf was not created during conversion'

    content_blob.extract_text_from_pdf

    assert File.exist? content_blob.filepath('txt')

    content = File.open(content_blob.filepath('txt'), 'rb').read
    assert content.include?('This is an open office power point odp format')
  end

  test 'convert_office should convert rtf to pdf and then docsplit converts pdf to txt' do
    check_for_soffice
    content_blob = Factory(:rtf_content_blob, uuid: 'rtf_1')
    assert File.exist? content_blob.filepath
    FileUtils.rm content_blob.filepath('pdf') if File.exist? content_blob.filepath('pdf')
    assert !File.exist?(content_blob.filepath('pdf'))

    content_blob.convert_to_pdf

    assert File.exist?(content_blob.filepath('pdf')), 'pdf was not created during conversion'

    content_blob.extract_text_from_pdf

    assert File.exist? content_blob.filepath('txt')

    content = File.open(content_blob.filepath('txt'), 'rb').read

    assert content.mb_chars.normalize.include?('This is a rtf format')
  end

  test 'convert_office should convert txt to pdf' do
    check_for_soffice
    content_blob = Factory(:txt_content_blob, uuid: 'txt_1')
    assert File.exist? content_blob.filepath
    FileUtils.rm content_blob.filepath('pdf') if File.exist? content_blob.filepath('pdf')
    assert !File.exist?(content_blob.filepath('pdf'))

    content_blob.convert_to_pdf

    assert File.exist?(content_blob.filepath('pdf')), 'pdf was not created during conversion'
  end

  test 'is_content_viewable?' do
    Seek::Config.stub(:pdf_conversion_enabled, true) do
      viewable_formats = %w[application/pdf]
      viewable_formats << 'application/msword'
      viewable_formats << 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      viewable_formats << 'application/vnd.ms-powerpoint'
      viewable_formats << 'application/vnd.openxmlformats-officedocument.presentationml.presentation'
      viewable_formats << 'application/vnd.oasis.opendocument.text'
      viewable_formats << 'application/vnd.oasis.opendocument.presentation'
      viewable_formats << 'application/rtf'

      viewable_formats.each do |viewable_format|
        cb_with_content_viewable_format = Factory(:content_blob, content_type: viewable_format, asset: Factory(:sop), data: File.new("#{Rails.root}/test/fixtures/files/a_pdf_file.pdf", 'rb').read)
        User.with_current_user cb_with_content_viewable_format.asset.contributor do
          assert cb_with_content_viewable_format.is_viewable_format?
          assert cb_with_content_viewable_format.is_content_viewable?
        end
      end
      cb_with_no_viewable_format = Factory(:content_blob, content_type: 'application/excel', asset: Factory(:sop), data: File.new("#{Rails.root}/test/fixtures/files/spreadsheet.xls", 'rb').read)
      User.with_current_user cb_with_no_viewable_format.asset.contributor do
        refute cb_with_no_viewable_format.is_viewable_format?
        refute cb_with_no_viewable_format.is_content_viewable?
      end

      #correct format but file doesn't exist
      blob = Factory(:content_blob, content_type: 'application/msword', asset: Factory(:sop))
      FileUtils.rm blob.filepath

      assert blob.is_viewable_format?
      refute blob.is_content_viewable?
    end
  end

  test 'content needing conversion should not be viewable when pdf_conversion is disabled' do
    with_config_value :pdf_conversion_enabled, false do
      viewable_formats = %w[doc_content_blob]
      viewable_formats << 'docx_content_blob'
      viewable_formats << 'ppt_content_blob'
      viewable_formats << 'pptx_content_blob'
      viewable_formats << 'odt_content_blob'
      viewable_formats << 'odp_content_blob'

      viewable_formats.each do |format|
        cb = Factory(format.to_s, asset:Factory(:sop))
        User.with_current_user cb.asset.contributor do
          refute cb.is_content_viewable?
        end
      end
    end
  end

  test 'content not needing conversion should be viewable when pdf_conversion is disabled' do
    pdf_content_blob = Factory(:content_blob, content_type: 'application/pdf', asset: Factory(:sop), data: File.new("#{Rails.root}/test/fixtures/files/a_pdf_file.pdf", 'rb').read)

    with_config_value :pdf_conversion_enabled, false do
      viewable_formats = %w[txt_content_blob csv_content_blob tsv_content_blob pdf_content_blob]

      viewable_formats.each do |format|
        cb = Factory(format.to_s,asset:Factory(:sop))
        User.with_current_user cb.asset.contributor do
          assert cb.is_content_viewable?
        end
      end

    end
  end

  test 'filter_text_content' do
    check_for_soffice
    ms_word_sop_cb = Factory(:doc_content_blob)
    content = "test \n content \f only"
    filtered_content = ms_word_sop_cb.send(:filter_text_content, content)
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
    assert pdf_content_blob.is_pdf?
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
    stub_request(:head, 'http://www.abc.com').to_return(headers: { content_length: 500, content_type: 'text/plain' }, status: 200)
    blob = Factory(:url_content_blob)
    assert_equal 500, blob.file_size
  end

  test 'calculates checksums of remote content' do
    stub_request(:head, 'http://www.abc.com').to_return(
        headers: { content_length: nil, content_type: 'text/plain' }, status: 200
    )
    stub_request(:get, 'http://www.abc.com').to_return(
        body: File.new("#{Rails.root}/test/fixtures/files/checksums.txt"),
        headers: { content_type: 'text/plain' }, status: 200)

    blob = Factory(:url_content_blob)
    blob.save
    blob.reload
    assert !blob.file_exists?
    assert blob.md5sum.blank?
    assert blob.sha1sum.blank?

    blob.retrieve

    assert blob.reload.file_exists?
    assert_equal 'd41d8cd98f00b204e9800998ecf8427e', blob.md5sum
    assert_equal 'da39a3ee5e6b4b0d3255bfef95601890afd80709', blob.sha1sum
  end

  test 'can retrieve remote content' do
    stub_request(:head, 'http://www.abc.com').to_return(
      headers: { content_length: nil, content_type: 'text/plain' }, status: 200
    )
    stub_request(:get, 'http://www.abc.com').to_return(body: 'abcdefghij' * 500,
                                                       headers: { content_type: 'text/plain' }, status: 200)

    blob = Factory(:url_content_blob)
    assert !blob.file_exists?
    assert_nil blob.file_size

    blob.retrieve
    assert blob.file_exists?
    assert_equal 5000, blob.file_size
  end

  test "won't retrieve remote content over hard limit" do
    # Web server lies about content length:
    stub_request(:head, 'http://www.abc.com').to_return(
      headers: { content_length: 500, content_type: 'text/plain' }, status: 200
    )
    # Size is actually 6kb:
    stub_request(:get, 'http://www.abc.com').to_return(body: 'abcdefghij' * 600,
                                                       headers: { content_type: 'text/plain' }, status: 200)

    blob = Factory(:url_content_blob)
    assert !blob.file_exists?
    assert_equal 500, blob.file_size

    with_config_value(:hard_max_cachable_size, 5000) do
      assert_raise Seek::DownloadHandling::SizeLimitExceededException do
        blob.retrieve
      end
    end
    assert !blob.file_exists?
  end

  test "won't endlessly follow redirects when downloading remote content" do
    stub_request(:head, 'http://www.abc.com').to_return(
      headers: { content_length: 500, content_type: 'text/plain' }, status: 200
    )
    # Infinitely redirects
    stub_request(:get, 'http://www.abc.com').to_return(headers: { location: 'http://www.abc.com' }, status: 302)

    blob = Factory(:url_content_blob)
    assert !blob.file_exists?
    assert_equal 500, blob.file_size

    assert_raise Seek::DownloadHandling::RedirectLimitExceededException do
      blob.retrieve
    end
    assert !blob.file_exists?
  end

  test 'raises exception on bad response code when downloading remote content' do
    stub_request(:head, 'http://www.abc.com').to_return(
      headers: { content_length: 500, content_type: 'text/plain' }, status: 200
    )
    stub_request(:get, 'http://www.abc.com').to_return(status: 404)

    blob = Factory(:url_content_blob)
    assert !blob.file_exists?
    assert_equal 500, blob.file_size

    assert_raise Seek::DownloadHandling::BadResponseCodeException do
      blob.retrieve
    end
    assert !blob.file_exists?
  end

  test 'handles relative redirects when downloading remote content' do
    stub_request(:head, 'http://www.abc.com').to_return(headers: { location: '/xyz' }, status: 302)
    stub_request(:get, 'http://www.abc.com').to_return(headers: { location: '/xyz' }, status: 302)
    stub_request(:head, 'http://www.abc.com/xyz').to_return(
      headers: { content_length: nil, content_type: 'text/plain' }, status: 200
    )
    stub_request(:get, 'http://www.abc.com/xyz').to_return(body: 'abcdefghij' * 500,
                                                           headers: { content_type: 'text/plain' }, status: 200)

    blob = Factory(:url_content_blob)
    assert !blob.file_exists?
    assert_nil blob.file_size

    blob.retrieve
    assert blob.file_exists?
    assert_equal 5000, blob.file_size
  end

  test 'handles absolute redirects when downloading remote content' do
    stub_request(:head, 'http://www.abc.com').to_return(headers: { location: 'http://www.abc.com/xyz' }, status: 302)
    stub_request(:get, 'http://www.abc.com').to_return(headers: { location: 'http://www.abc.com/xyz' }, status: 302)
    stub_request(:head, 'http://www.abc.com/xyz').to_return(
      headers: { content_length: nil, content_type: 'text/plain' }, status: 200
    )
    stub_request(:get, 'http://www.abc.com/xyz').to_return(body: 'abcdefghij' * 500,
                                                           headers: { content_type: 'text/plain' }, status: 200)

    blob = Factory(:url_content_blob)
    assert !blob.file_exists?
    assert_nil blob.file_size

    blob.retrieve
    assert blob.file_exists?
    assert_equal 5000, blob.file_size
  end

  test 'handles mixed redirects when downloading remote content' do
    stub_request(:head, 'http://www.abc.com').to_return(headers: { location: 'http://www.xyz.com' }, status: 302)
    stub_request(:get, 'http://www.abc.com').to_return(headers: { location: 'http://www.xyz.com' }, status: 302)
    stub_request(:head, 'http://www.xyz.com').to_return(headers: { location: '/xyz' }, status: 302)
    stub_request(:get, 'http://www.xyz.com').to_return(headers: { location: '/xyz' }, status: 302)
    stub_request(:head, 'http://www.xyz.com/xyz').to_return(
      headers: { content_length: nil, content_type: 'text/plain' }, status: 200
    )
    stub_request(:get, 'http://www.xyz.com/xyz').to_return(body: 'abcdefghij' * 500,
                                                           headers: { content_type: 'text/plain' }, status: 200)

    blob = Factory(:url_content_blob)
    assert !blob.file_exists?
    assert_nil blob.file_size

    blob.retrieve
    assert blob.file_exists?
    assert_equal 5000, blob.file_size
  end

  test "won't retrieve remote content from internal network" do
    begin
      # Need to allow the request through so that `private_address_check` can catch it.
      WebMock.allow_net_connect!
      VCR.turned_off do
        assert PrivateAddressCheck.resolves_to_private_address?('localhost')

        blob = Factory(:url_content_blob, url: 'http://localhost/secrets')
        assert !blob.file_exists?

        assert_raise PrivateAddressCheck::PrivateConnectionAttemptedError do
          blob.retrieve
        end

        assert !blob.file_exists?
      end
    ensure
      WebMock.disable_net_connect!(allow_localhost: true)
    end
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

  test 'can retrieve from NeLS' do
    setup_nels_for_units

    blob = ContentBlob.create(url: "https://test-fe.cbu.uib.no/nels/pages/sbi/sbi.xhtml?ref=#{@reference}")

    VCR.use_cassette('nels/get_sample_metadata') do
      blob.retrieve_from_nels(@nels_access_token)
    end
    blob.reload

    assert blob.is_excel?
    assert blob.file_size > 0
  end

  test 'raises 404 when nels sample metadata missing' do
    setup_nels_for_units

    blob = ContentBlob.create(url: 'https://test-fe.cbu.uib.no/nels/pages/sbi/sbi.xhtml?ref=404')

    assert_raises(RestClient::ResourceNotFound) do
      VCR.use_cassette('nels/missing_sample_metadata') do
        blob.retrieve_from_nels(@nels_access_token)
      end
    end
  end

  test 'added timestamps' do
    t1 = 1.day.ago
    blob = nil
    travel_to(t1) do
      blob = Factory(:content_blob)
      assert_equal t1.to_s, blob.created_at.to_s
      assert_equal t1.to_s, blob.updated_at.to_s
    end

    t2 = 1.hour.ago
    travel_to(t2) do
      blob.content_type = 'text/xml'
      blob.save!
      assert_equal t2.to_s, blob.updated_at.to_s
    end
  end

  test 'deletes image files after destroy' do
    blob = Factory(:image_content_blob)
    filepath = blob.file_path
    refute_nil filepath
    assert File.exist?(filepath)
    assert_difference('ContentBlob.count', -1) do
      blob.destroy
    end
    refute File.exist?(filepath)
  end

  test 'deletes files after destroy' do
    blob = Factory(:spreadsheet_content_blob)
    filepath = blob.file_path
    refute_nil filepath
    assert File.exist?(filepath)
    assert_difference('ContentBlob.count', -1) do
      blob.destroy
    end
    refute File.exist?(filepath)
  end

  test 'deletes converted files after destroy' do
    blob = Factory(:doc_content_blob)
    pdf_path = blob.filepath('pdf')
    txt_path = blob.filepath('txt')

    # pretend the conversion has taken place
    FileUtils.touch(pdf_path)
    FileUtils.touch(txt_path)

    assert File.exist?(pdf_path)
    assert File.exist?(txt_path)
    assert_difference('ContentBlob.count', -1) do
      blob.destroy
    end
    refute File.exist?(pdf_path)
    refute File.exist?(txt_path)
  end

  test 'fix mime type after failed csv extraction' do
    blob = Factory(:image_content_blob, content_type:'application/excel', original_filename:'image.xls')
    assert blob.is_excel?

    text = blob.to_csv

    assert text.blank?

    blob.reload

    refute blob.is_excel?
    assert_equal 'image/png',blob.content_type
  end

  test 'fix mime type after failed pdf contents for search' do
    check_for_soffice
    blob = Factory(:image_content_blob, content_type: 'application/msword', original_filename: 'image.doc')
    assert blob.is_pdf_convertable?

    assert_empty blob.pdf_contents_for_search

    blob.reload

    refute blob.is_pdf_convertable?
    assert_equal 'image/png', blob.content_type

    # incorrectly described as pdf
    blob = Factory(:image_content_blob, content_type: 'application/pdf', original_filename: 'image.pdf')

    assert_empty blob.pdf_contents_for_search

    blob.reload

    refute blob.is_pdf_convertable?
    assert_equal 'image/png', blob.content_type

    # handles when the file is actually broken, rather than failing due to the mime type
    blob = Factory(:broken_pdf_content_blob)
    assert_empty blob.pdf_contents_for_search
    assert_equal 'application/pdf', blob.content_type
  end

  test 'fix mime type after spreadsheet xml fail' do
    blob = Factory(:image_content_blob, content_type:'application/msexcel', original_filename:'image.xls')
    assert blob.is_extractable_spreadsheet?

    assert_raises(SysMODB::SpreadsheetExtractionException) do
      blob.to_spreadsheet_xml
    end

    blob.reload

    refute blob.is_extractable_spreadsheet?
    assert_equal 'image/png',blob.content_type
  end

  test 'tmp_io_objects in tmp dir are deleted' do
    file = Tempfile.new('testing-content-blob')
    file.write('test test test')
    file.close

    assert File.exists?(file.path)
    tmp_object = File.open(file.path)
    blob = ContentBlob.create(original_filename:'testing-content-blob.txt', tmp_io_object: tmp_object)
    assert blob.file_exists?
    assert_equal 14,blob.file_size
    refute File.exists?(file.path)
  end

  test 'tmp_io_object not in tmp are not deleted' do
    #files outside of tmp/ shouldn't be cleaned up as they may just be needed for copy
    path = File.join(Seek::Config.temporary_filestore_path,'test-content-blob.txt')
    file = File.open(path,'w')
    file.write('test test test')
    file.close
    tmp_object = File.open(path)
    blob = ContentBlob.create(original_filename:'testing-content-blob.txt', tmp_io_object: tmp_object)
    assert blob.file_exists?
    assert_equal 14,blob.file_size
    assert File.exists?(path)
    File.delete(path)
  end

  test 'enqueues remote content fetching job' do
    content_blob = Factory.build(:url_content_blob, make_local_copy: true)
    refute content_blob.remote_content_fetch_task.pending?
    assert_difference('Task.count', 1) do
      assert_enqueued_with(job: RemoteContentFetchingJob, args: [content_blob]) do
        content_blob.save!
        assert content_blob.remote_content_fetch_task.pending?
      end
    end
  end

  test 'does not enqueue remote content fetching job for local content blob' do
    content_blob = Factory.build(:content_blob)
    assert_no_difference('Task.count') do
      assert_no_enqueued_jobs(only: RemoteContentFetchingJob) do
        content_blob.save!
        refute content_blob.remote_content_fetch_task.pending?
      end
    end
  end

  test 'can destroy unsaved content blob without Cannot Modify Frozen Hash error' do
    assert_nothing_raised do
      ContentBlob.new.destroy
    end
  end
end
