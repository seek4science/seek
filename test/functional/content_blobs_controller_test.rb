require 'test_helper'
require 'webmock/test_unit'

class ContentBlobsControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:quentin)
  end

  test 'should find_and_auth_asset for get_pdf' do
    sop1 = Factory(:pdf_sop, policy: Factory(:all_sysmo_downloadable_policy))

    get :get_pdf, sop_id: sop1.id, id: sop1.content_blob.id
    assert_response :success

    sop2 = Factory(:pdf_sop, policy: Factory(:private_policy))
    get :get_pdf, sop_id: sop2.id, id: sop2.content_blob.id
    assert_redirected_to sop2
    assert_not_nil flash[:error]
  end

  test "examine url to file" do
    #test successful request to file
    stub_request(:head, "http://mockedlocation.com/a-piccy.png").to_return(:status => 200, :headers=>{'Content-Type' => 'image/png'})
    xml_http_request :get, :examine_url, :data_url=>"http://mockedlocation.com/a-piccy.png"
    assert_response :success
    assert @response.body.include?("not a webpage")
    refute assigns(:error)
    refute assigns(:error_msg)
    refute assigns(:unauthorized)
    refute assigns(:is_webpage)
  end

  test "examine url to webpage" do
    #successful request to webpage
    stub_request(:any, "http://somewhere.com").to_return(:body => "", :status => 200, :headers=>{'Content-Type' => 'text/html'})
    xml_http_request :get, :examine_url, :data_url=>"http://somewhere.com"
    assert_response :success
    assert @response.body.include?("This is a webpage")
    refute assigns(:error)
    refute assigns(:error_msg)
    refute assigns(:unauthorized)
    assert assigns(:is_webpage)
  end

  test "examine url unauthorized" do
    #unauthorized
    stub_request(:head, "http://unauth.com/file.pdf").to_return(:status => 403, :headers=>{'Content-Type' => 'application/pdf'})
    xml_http_request :get, :examine_url, :data_url=>"http://unauth.com/file.pdf"
    assert_response :success
    assert @response.body.include?("Access to this link is unauthorized")
    refute assigns(:error)
    refute assigns(:error_msg)
    assert assigns(:unauthorized)
  end

  test "examine url 404" do
    #404
    stub_request(:head, "http://missing.com").to_return(:status => 404, :headers=>{'Content-Type' => 'text/html'})
    xml_http_request :get, :examine_url, :data_url=>"http://missing.com"
    assert_response :success
    assert @response.body.include?("Nothing can be found at that URL")
    assert assigns(:error)
    assert assigns(:error_msg)
    refute assigns(:unauthorized)
  end

  test "examine url host not found" do
    #doesn't exist
    stub_request(:head, "http://nohost.com").to_raise(SocketError)
    xml_http_request :get, :examine_url, :data_url=>"http://nohost.com"
    assert_response :success
    assert @response.body.include?("Nothing can be found at that URL")
    assert assigns(:error)
    assert assigns(:error_msg)
    refute assigns(:unauthorized)
  end

  test "examine url bad uri" do
    #bad uri
    xml_http_request :get, :examine_url, :data_url=>"this is not a uri"
    assert_response :success
    assert @response.body.include?("The URL appears to be invalid")
    assert assigns(:error)
    assert assigns(:error_msg)
    refute assigns(:unauthorized)
  end

  test 'should find_and_auth_asset for download' do
    sop1 = Factory(:pdf_sop, policy: Factory(:all_sysmo_downloadable_policy))

    get :download, sop_id: sop1.id, id: sop1.content_blob.id
    assert_response :success

    sop2 = Factory(:pdf_sop, policy: Factory(:private_policy))
    get :download, sop_id: sop2.id, id: sop2.content_blob.id
    assert_redirected_to sop2
    assert_not_nil flash[:error]
  end

  test 'should find_and_auth_content_blob for get_pdf' do
    sop1 = Factory(:pdf_sop, policy: Factory(:all_sysmo_downloadable_policy))
    sop2 = Factory(:pdf_sop, policy: Factory(:private_policy))

    get :get_pdf, sop_id: sop1.id, id: sop1.content_blob.id
    assert_response :success

    get :get_pdf, sop_id: sop1.id, id: sop2.content_blob.id
    assert_redirected_to :root
    assert_not_nil flash[:error]
  end

  test 'should find_and_auth_content_blob for download' do
    sop1 = Factory(:pdf_sop, policy: Factory(:all_sysmo_downloadable_policy))
    sop2 = Factory(:pdf_sop, policy: Factory(:private_policy))

    get :download, sop_id: sop1.id, id: sop1.content_blob.id
    assert_response :success

    get :download, sop_id: sop1.id, id: sop2.content_blob.id
    assert_redirected_to :root
    assert_not_nil flash[:error]
  end

  test 'should download without type information' do
    model = Factory :typeless_model, policy: Factory(:public_policy)

    assert_difference('ActivityLog.count') do
      get :download, model_id: model.id, id: model.content_blobs.first.id
    end
    assert_response :success
    assert_equal "attachment; filename=\"file_with_no_extension\"", @response.header['Content-Disposition']
    assert_equal 'application/octet-stream', @response.header['Content-Type']
    assert_equal '31', @response.header['Content-Length']
  end

  test 'get_pdf' do
    check_for_soffice
    ms_word_sop = Factory(:doc_sop, policy: Factory(:all_sysmo_downloadable_policy))
    pdf_path = ms_word_sop.content_blob.filepath('pdf')
    FileUtils.rm pdf_path if File.exist?(pdf_path)
    assert !File.exist?(pdf_path)
    assert ms_word_sop.can_download?

    get :get_pdf, sop_id: ms_word_sop.id, id: ms_word_sop.content_blob.id
    assert_response :success

    assert_equal "attachment; filename=\"ms_word_test.pdf\"", @response.header['Content-Disposition']
    assert_equal 'application/pdf', @response.header['Content-Type']
    # assert_equal 16235, @response.header['Content-Length'].to_i
    assert_includes 9200..16_300, @response.header['Content-Length'].to_i, 'the content length should fall within the rage 9200-9300 bytes'

    assert File.exist?(ms_word_sop.content_blob.filepath)
    assert File.exist?(pdf_path)
  end

  test 'get_pdf from url' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/a_pdf_file.pdf", 'http://somewhere.com/piccy.pdf', 'Content-Type' => 'application/pdf'
    pdf_sop = Factory(:sop,
                      policy: Factory(:all_sysmo_downloadable_policy),
                      content_blob: Factory(:pdf_content_blob,
                                            data: nil,
                                            url: 'http://somewhere.com/piccy.pdf',
                                            uuid: UUIDTools::UUID.random_create.to_s))
    assert !pdf_sop.content_blob.file_exists?

    get :get_pdf, sop_id: pdf_sop.id, id: pdf_sop.content_blob.id

    assert_response :success

    assert_equal "attachment; filename=\"a_pdf_file.pdf\"", @response.header['Content-Disposition']
    assert_equal 'application/pdf', @response.header['Content-Type']
    assert_equal '8827', @response.header['Content-Length']

    assert !File.exist?(pdf_sop.content_blob.filepath)
    assert !File.exist?(pdf_sop.content_blob.filepath('pdf'))
  end

  test 'get_pdf of a doc file from url' do
    check_for_soffice
    mock_remote_file "#{Rails.root}/test/fixtures/files/ms_word_test.doc", 'http://somewhere.com/piccy.doc', 'Content-Type' => 'application/pdf'
    doc_sop = Factory(:sop,
                      policy: Factory(:all_sysmo_downloadable_policy),
                      content_blob: Factory(:doc_content_blob,
                                            data: nil,
                                            url: 'http://somewhere.com/piccy.doc',
                                            uuid: UUIDTools::UUID.random_create.to_s))

    get :get_pdf, sop_id: doc_sop.id, id: doc_sop.content_blob.id
    assert_response :success
    assert_equal "attachment; filename=\"ms_word_test.pdf\"", @response.header['Content-Disposition']
    assert_equal 'application/pdf', @response.header['Content-Type']
    # assert_equal 16235, @response.header['Content-Length'].to_i
    assert_includes 9200..16_300, @response.header['Content-Length'].to_i, 'the content length should fall within the rage 9200-9300 bytes'

    assert !File.exist?(doc_sop.content_blob.filepath)
    assert File.exist?(doc_sop.content_blob.filepath('pdf')), 'the converted file should remain'
  end

  test 'should gracefully handle view_pdf for non existing asset' do
    stub_request(:head, "http://somewhere.com/piccy.doc").to_return(:status=>404)
    sop = Factory(:sop,
                  policy: Factory(:all_sysmo_downloadable_policy),
                  content_blob: Factory(:doc_content_blob,
                                        data: nil,
                                        url: 'http://somewhere.com/piccy.doc',
                                        uuid: UUIDTools::UUID.random_create.to_s))
    blob = sop.content_blob
    get :get_pdf, sop_id: 999, id: blob.id
    assert_redirected_to root_path
    assert_not_nil flash[:error]

  end

  test 'report error when file unavailable for download' do
    df = Factory :data_file, policy: Factory(:public_policy)
    df.content_blob.dump_data_to_file
    assert df.content_blob.file_exists?
    FileUtils.rm df.content_blob.filepath
    assert !df.content_blob.file_exists?

    get :download, data_file_id: df, id: df.content_blob

    assert_redirected_to df
    assert flash[:error].match(/Unable to find a copy of the file for download/)
  end

  test 'get view pdf content' do
    sop = Factory(:pdf_sop, policy: Factory(:all_sysmo_downloadable_policy))

    assert_difference('ActivityLog.count') do
      get :view_pdf_content, sop_id: sop.id, id: sop.content_blob.id
    end

    assert_response :success

    download_path = download_sop_content_blob_path(sop, sop.content_blob.id, format: :pdf, intent: :inline_view)
    assert @response.body.include?("DEFAULT_URL = '#{download_path}'")

    al = ActivityLog.last
    assert_equal 'inline_view', al.action
    assert_equal sop.content_blob, al.referenced
    assert_equal sop, al.activity_loggable
    assert_equal User.current_user, al.culprit
    assert_equal 'content_blobs', al.controller_name
  end

  # This test is quite fragile, because it relies on an external resource
  test 'should redirect on download for 302 url' do
    mock_http
    df  = Factory :data_file,
                  policy: Factory(:all_sysmo_downloadable_policy),
                  content_blob: Factory(:url_content_blob,
                                        url: 'http://mocked302.com',
                                        uuid: UUIDTools::UUID.random_create.to_s)
    assert !df.content_blob.file_exists?

    get :download, data_file_id: df, id: df.content_blob
    assert_redirected_to 'http://mocked302.com'
  end

  # This test is quite fragile, because it relies on an external resource
  test 'should redirect on download for 401 url' do
    mock_http
    df  = Factory :data_file,
                  policy: Factory(:all_sysmo_downloadable_policy),
                  content_blob: Factory(:url_content_blob,
                                        url: 'http://mocked401.com',
                                        uuid: UUIDTools::UUID.random_create.to_s)
    assert !df.content_blob.file_exists?

    get :download, data_file_id: df, id: df.content_blob
    assert_redirected_to 'http://mocked401.com'
  end

  test 'should download' do
    df = Factory :small_test_spreadsheet_datafile, policy: Factory(:public_policy), contributor: User.current_user
    assert_difference('ActivityLog.count') do
      get :download, data_file_id: df, id: df.content_blob
    end
    assert_response :success
    assert_equal "attachment; filename=\"small-test-spreadsheet.xls\"", @response.header['Content-Disposition']
    assert_equal 'application/excel', @response.header['Content-Type']
    assert_equal '7168', @response.header['Content-Length']
  end

  test 'should not log download for inline view intent' do
    df = Factory :small_test_spreadsheet_datafile, policy: Factory(:public_policy), contributor: User.current_user
    assert_no_difference('ActivityLog.count') do
      get :download, data_file_id: df, id: df.content_blob, intent: :inline_view
    end
    assert_response :success
  end

  test 'should download from url' do
    mock_http
    df  = Factory :data_file,
                  policy: Factory(:all_sysmo_downloadable_policy),
                  content_blob: Factory(:url_content_blob,
                                        url: 'http://mockedlocation.com/a-piccy.png',
                                        uuid: UUIDTools::UUID.random_create.to_s)
    assert_difference('ActivityLog.count') do
      get :download, data_file_id: df, id: df.content_blob
    end
    assert_response :success
  end

  test 'should gracefully handle when downloading a unknown host url' do
    mock_http
    df  = Factory :data_file,
                  policy: Factory(:all_sysmo_downloadable_policy),
                  content_blob: Factory(:url_content_blob,
                                        url: 'http://unknownhost.com/pic.png',
                                        uuid: UUIDTools::UUID.random_create.to_s)

    get :download, data_file_id: df, id: df.content_blob

    assert_redirected_to data_file_path(df, version: df.version)
    assert_not_nil flash[:error]
  end

  test 'should gracefully handle when downloading a url resulting in 404' do
    mock_http
    df  = Factory :data_file,
                  policy: Factory(:all_sysmo_downloadable_policy),
                  content_blob: Factory(:url_content_blob,
                                        url: 'http://mocked404.com',
                                        uuid: UUIDTools::UUID.random_create.to_s)

    get :download, data_file_id: df, id: df.content_blob
    assert_redirected_to data_file_path(df, version: df.version)
    assert_not_nil flash[:error]
  end

  test 'should handle inline download when specify the inline disposition' do
    data = File.new("#{Rails.root}/test/fixtures/files/file_picture.png", 'rb').read
    df = Factory :data_file,
                 content_blob: Factory(:content_blob, data: data, content_type: 'images/png'),
                 policy: Factory(:downloadable_public_policy)

    get :download, data_file_id: df, id: df.content_blob, disposition: 'inline'
    assert_response :success
    assert @response.header['Content-Disposition'].include?('inline')
  end

  test 'should handle normal attachment download' do
    data = File.new("#{Rails.root}/test/fixtures/files/file_picture.png", 'rb').read
    df = Factory :data_file,
                 content_blob: Factory(:content_blob, data: data, content_type: 'images/png'),
                 policy: Factory(:downloadable_public_policy)

    get :download, data_file_id: df, id: df.content_blob
    assert_response :success
    assert @response.header['Content-Disposition'].include?('attachment')
  end

  test 'activity correctly logged' do
    model = Factory :model_2_files, policy: Factory(:public_policy), contributor: User.current_user
    first_content_blob = model.content_blobs.first
    assert_difference('ActivityLog.count') do
      get :download, model_id: model.id, id: first_content_blob.id
    end
    assert_response :success
    al = ActivityLog.last
    assert_equal model, al.activity_loggable
    assert_equal 'download', al.action
    assert_equal first_content_blob, al.referenced
    assert_equal User.current_user, al.culprit
    assert_equal 'content_blobs', al.controller_name
  end

  test 'should download identical file from file list' do
    model = Factory :model_2_files, policy: Factory(:public_policy), contributor: User.current_user
    first_content_blob = model.content_blobs.first
    assert_difference('ActivityLog.count') do
      get :download, model_id: model.id, id: first_content_blob.id
    end
    assert_response :success
    assert_equal "attachment; filename=\"#{first_content_blob.original_filename}\"", @response.header['Content-Disposition']
    assert_equal first_content_blob.content_type, @response.header['Content-Type']
    assert_equal first_content_blob.filesize.to_s, @response.header['Content-Length']
  end

  private
  def mock_http
    file = "#{Rails.root}/test/fixtures/files/file_picture.png"
    stub_request(:get, 'http://mockedlocation.com/a-piccy.png').to_return(body: File.new(file), status: 200, headers: { 'Content-Type' => 'image/png' })
    stub_request(:head, 'http://mockedlocation.com/a-piccy.png')

    stub_request(:any, 'http://mocked302.com').to_return(status: 302)
    stub_request(:any, 'http://mocked401.com').to_return(status: 401)
    stub_request(:any, 'http://mocked404.com').to_return(status: 404)

    stub_request(:any, 'http://unknownhost.com/pic.png').to_raise(SocketError)
  end
end
