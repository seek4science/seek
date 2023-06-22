require 'test_helper'
require 'minitest/mock'
require 'private_address_check'

class ContentBlobsControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:quentin)
  end

  test 'should resolve to json' do
    sop = FactoryBot.create(:pdf_sop, policy: FactoryBot.create(:all_sysmo_downloadable_policy))
    blob = sop.content_blob

    get :show, params: { id: blob.id, sop_id: sop.id, format: 'json' }
    assert_response :success
    perform_jsonapi_checks
  end

  test 'html and rdf not acceptable' do
    sop = FactoryBot.create(:pdf_sop, policy: FactoryBot.create(:all_sysmo_downloadable_policy))
    blob = sop.content_blob

    get :show, params: { id: blob.id, sop_id: sop.id }
    assert_response :not_acceptable

    get :show, params: { id: blob.id, sop_id: sop.id, format: 'rdf' }
    assert_response :not_acceptable
  end

  test 'should fail for unauthorized json' do
    sop = FactoryBot.create(:pdf_sop, policy: FactoryBot.create(:private_policy))
    blob = sop.content_blob

    get :show, params: { id: blob.id, sop_id: sop.id, format: 'json' }
    assert_response :forbidden
  end

  test 'should find_and_auth_asset for get_pdf' do
    sop1 = FactoryBot.create(:pdf_sop, policy: FactoryBot.create(:all_sysmo_downloadable_policy))

    get :get_pdf, params: { sop_id: sop1.id, id: sop1.content_blob.id }
    assert_response :success

    sop2 = FactoryBot.create(:pdf_sop, policy: FactoryBot.create(:private_policy))
    get :get_pdf, params: { sop_id: sop2.id, id: sop2.content_blob.id }
    assert_redirected_to sop2
    assert_not_nil flash[:error]
  end

  test 'examine url to file' do
    # test successful request to file
    stub_request(:head, 'http://mockedlocation.com/a-piccy.png').to_return(status: 200, headers: { 'Content-Type' => 'image/png' })
    get :examine_url, xhr: true, params: { data_url: 'http://mockedlocation.com/a-piccy.png' }
    assert_response :success
    assert_equal 200, assigns(:info)[:code]
    assert !@response.body.include?('Webpage Link')
    assert_equal 'file', assigns(:type)
  end

  test 'examine url to webpage' do
    # successful request to webpage
    stub_request(:any, 'http://somewhere.com').to_return(body: '', status: 200, headers: { 'Content-Type' => 'text/html' })
    get :examine_url, xhr: true, params: { data_url: 'http://somewhere.com' }
    assert_response :success
    assert_equal 200, assigns(:info)[:code]
    assert @response.body.include?('Webpage Link')
    assert_equal 'webpage', assigns(:type)
  end

  test 'examine url to github' do
    stub_request(:any, 'https://github.com/bob/workflows/blob/master/dir/the_workflow.cwl').to_return(status: 200)
    stub_request(:any, 'https://raw.githubusercontent.com/bob/workflows/master/dir/the_workflow.cwl').to_return(
        body: File.new("#{Rails.root}/test/fixtures/files/workflows/rp2/workflows/rp2-to-rp2path.cwl"),
        status: 200,
        headers: { 'Content-Length' => 1118,
                   'Content-Type' => 'text/plain' })

    get :examine_url, xhr: true, params: { data_url: 'https://github.com/bob/workflows/blob/master/dir/the_workflow.cwl' }
    assert_response :success
    assert @response.body.include?('GitHub')
    assert_equal 200, assigns(:info)[:code]
    assert_equal 'github', assigns(:type)
    assert_equal 'bob', assigns(:info)[:github_user]
    assert_equal 'workflows', assigns(:info)[:github_repo]
    assert_equal 'master', assigns(:info)[:github_branch]
    assert_equal 'dir/the_workflow.cwl', assigns(:info)[:github_path]
    assert_equal 1118, assigns(:info)[:file_size]
    assert_equal 'the_workflow.cwl', assigns(:info)[:file_name]
  end

  test 'examine url to galaxy instance works with the various workflow endpoints' do
    stub_request(:any, 'https://galaxy-instance.biz/banana/workflows/run?id=123').to_return(status: 200)
    stub_request(:any, 'https://galaxy-instance.biz/banana/workflow/export_to_file?id=123').to_return(
        body: File.new("#{Rails.root}/test/fixtures/files/workflows/1-PreProcessing.ga"),
        status: 200,
        headers: { 'Content-Length' => 40296,
                   'Content-Type' => 'text/plain',
                   'Content-Disposition' => "attachment; filename=\"1-PreProcessing.ga\"; filename*=UTF-8''1-PreProcessing.ga"})

    suite = -> (url) {
      get :examine_url, xhr: true, params: { data_url: url }
      assert_response :success
      assert @response.body.include?('Galaxy')
      assert_equal 200, assigns(:info)[:code]
      assert_equal 'galaxy', assigns(:type)
      assert_equal '123', assigns(:info)[:workflow_id]
      assert_equal 'https://galaxy-instance.biz/banana/', assigns(:info)[:galaxy_host].to_s
      assert_equal 'https://galaxy-instance.biz/banana/workflow/display_by_id?id=123', assigns(:info)[:display_url]
      assert_equal 40296, assigns(:info)[:file_size]
      assert_equal '1-PreProcessing.ga', assigns(:info)[:file_name]
    }

    suite.call('https://galaxy-instance.biz/banana/workflows/run?id=123')
    suite.call('https://galaxy-instance.biz/banana/workflow/export_to_file?id=123')
    suite.call('https://galaxy-instance.biz/banana/workflow/display_by_id?id=123')
  end

  test 'examine url does not crash when examining galaxy-like URL' do
    url = "https://training.galaxyproject.org/training-material/topics/metagenomics/tutorials/plasmid-metagenomics-nanopore/workflows/Workflow-plasmid-metagenomics-nanopore.ga"
    stub_request(:any, url).to_return(
      body: File.new("#{Rails.root}/test/fixtures/files/workflows/1-PreProcessing.ga"),
      status: 200,
      headers: { 'Content-Length' => 40296,
                 'Content-Type' => 'text/plain',
                 'Content-Disposition' => "attachment; filename=\"1-PreProcessing.ga\"; filename*=UTF-8''1-PreProcessing.ga"})

    get :examine_url, xhr: true, params: { data_url: url }
    assert_response :success
    assert @response.body.include?('Remote File')
    assert_equal 200, assigns(:info)[:code]
    assert_equal 'file', assigns(:type)
    assert_equal 'text/plain', assigns(:info)[:content_type]
    assert_equal 40296, assigns(:info)[:file_size]
    assert_equal '1-PreProcessing.ga', assigns(:info)[:file_name]
  end

  test 'examine url forbidden' do
    # forbidden
    stub_request(:head, 'http://unauth.com/file.pdf').to_return(status: 403, headers: { 'Content-Type' => 'application/pdf' })
    stub_request(:get, 'http://unauth.com/file.pdf').to_return(status: 403, headers: { 'Content-Type' => 'application/pdf' })
    get :examine_url, xhr: true, params: { data_url: 'http://unauth.com/file.pdf' }
    assert_response 200
    assert_equal 403, assigns(:info)[:code]
    assert @response.body.include?('Access to this link is unauthorized')
    assert_equal 'warning', assigns(:type)
    assert assigns(:warning_msg)
  end

  test 'examine url unauthorized' do
    # unauthorized
    stub_request(:head, 'http://unauth.com/file.pdf').to_return(status: 401, headers: { 'Content-Type' => 'application/pdf' })
    stub_request(:get, 'http://unauth.com/file.pdf').to_return(status: 401, headers: { 'Content-Type' => 'application/pdf' })
    get :examine_url, xhr: true, params: { data_url: 'http://unauth.com/file.pdf' }
    assert_response :success
    assert @response.body.include?('Access to this link is unauthorized')
    assert_equal 'warning', assigns(:type)
    assert assigns(:warning_msg)
  end

  test 'examine url 404' do
    # 404
    stub_request(:head, 'http://missing.com').to_return(status: 404, headers: { 'Content-Type' => 'text/html' })
    stub_request(:get, 'http://missing.com').to_return(status: 404, headers: { 'Content-Type' => 'text/html' })
    get :examine_url, xhr: true, params: { data_url: 'http://missing.com' }
    assert_response 400
    assert_equal 404, assigns(:info)[:code]
    assert @response.body.include?('Nothing can be found at that URL')
    assert_equal 'error', assigns(:type)
    assert assigns(:error_msg)
  end

  test 'examine url head 404 get 200' do
    stub_request(:head, 'https://onedrive.live.com/').to_return(status: 404, headers: { 'Content-Type' => 'text/html' })
    stub_request(:get, 'https://onedrive.live.com/').to_return(status: 200, headers: { 'Content-Type' => 'text/html' })
    get :examine_url, xhr: true, params: { data_url: 'https://onedrive.live.com/' }
    assert_response :success
    assert_equal 200, assigns(:info)[:code]
    assert @response.body.include?('Webpage Link')
    assert_equal 'webpage', assigns(:type)
    refute assigns(:error_msg)
    refute assigns(:warning_msg)
  end

  test 'examine url host not found' do
    # doesn't exist
    stub_request(:head, 'http://nohost.com').to_raise(SocketError)
    get :examine_url, xhr: true, params: { data_url: 'http://nohost.com' }
    assert_response 400
    assert_equal 404, assigns(:info)[:code]
    assert @response.body.include?('Nothing can be found at that URL')
    assert_equal 'error', assigns(:type)
    assert assigns(:error_msg)
  end

  test 'examine url bad uri' do
    # bad uri
    get :examine_url, xhr: true, params: { data_url: 'this is not a uri' }
    assert_response 400
    assert @response.body.include?('The URL appears to be invalid')
    assert_equal 'error', assigns(:type)
    assert assigns(:error_msg)
  end

  test 'examine url unrecognized scheme' do
    get :examine_url, xhr: true, params: { data_url: 'fish://tuna:1525125151' }
    assert_response :success
    assert @response.body.include?('Unhandled URL scheme')
    assert_equal 'warning', assigns(:type)
    assert assigns(:warning_msg)
  end

  test 'examine url localhost' do
    begin
      # Need to allow the request through so that `private_address_check` can catch it.
      WebMock.allow_net_connect!
      VCR.turned_off do
        get :examine_url, xhr: true, params: { data_url: 'http://localhost/secrets' }
        assert_response 400
        assert_equal 490, assigns(:info)[:code]
        assert @response.body.include?('URL is inaccessible')
        assert_equal 'error', assigns(:type)
        assert assigns(:error_msg)
      end
    ensure
      WebMock.disable_net_connect!(allow_localhost: true)
    end
  end

  test 'examine url local network' do
    begin
      # Need to allow the request through so that `private_address_check` can catch it.
      WebMock.allow_net_connect!
      assert PrivateAddressCheck.resolves_to_private_address?('192.168.0.1')
      VCR.turned_off do
        get :examine_url, xhr: true, params: { data_url: 'http://192.168.0.1/config' }
        assert_response 400
        assert_equal 490, assigns(:info)[:code]
        assert @response.body.include?('URL is inaccessible')
        assert_equal 'error', assigns(:type)
        assert assigns(:error_msg)
      end
    ensure
      WebMock.disable_net_connect!(allow_localhost: true)
    end
  end

  test 'should find_and_auth_asset for download' do
    sop1 = FactoryBot.create(:pdf_sop, policy: FactoryBot.create(:all_sysmo_downloadable_policy))

    get :download, params: { sop_id: sop1.id, id: sop1.content_blob.id }
    assert_response :success

    sop2 = FactoryBot.create(:pdf_sop, policy: FactoryBot.create(:private_policy))
    get :download, params: { sop_id: sop2.id, id: sop2.content_blob.id }
    assert_redirected_to sop2
    assert_not_nil flash[:error]
  end

  test 'should find_and_auth_content_blob for get_pdf' do
    sop1 = FactoryBot.create(:pdf_sop, policy: FactoryBot.create(:all_sysmo_downloadable_policy))
    sop2 = FactoryBot.create(:pdf_sop, policy: FactoryBot.create(:private_policy))

    get :get_pdf, params: { sop_id: sop1.id, id: sop1.content_blob.id }
    assert_response :success

    # don't match
    get :get_pdf, params: { sop_id: sop1.id, id: sop2.content_blob.id }
    assert_redirected_to :root
    assert_not_nil flash[:error]
  end

  test 'should find_and_auth_content_blob for download' do
    sop1 = FactoryBot.create(:pdf_sop, policy: FactoryBot.create(:all_sysmo_downloadable_policy))
    sop2 = FactoryBot.create(:pdf_sop, policy: FactoryBot.create(:private_policy))

    get :download, params: { sop_id: sop1.id, id: sop1.content_blob.id }
    assert_response :success

    # don't match
    get :download, params: { sop_id: sop1.id, id: sop2.content_blob.id }
    assert_redirected_to :root
    assert_not_nil flash[:error]
  end

  test 'should download without type information' do
    model = FactoryBot.create :typeless_model, policy: FactoryBot.create(:public_policy)

    assert_difference('ActivityLog.count') do
      get :download, params: { model_id: model.id, id: model.content_blobs.first.id }
    end
    assert_response :success
    assert_equal "attachment; filename=\"file_with_no_extension\"; filename*=UTF-8''file_with_no_extension", @response.header['Content-Disposition']
    assert_equal 'application/octet-stream', @response.header['Content-Type']
    assert_equal '31', @response.header['Content-Length']
  end

  test 'get_pdf' do
    ms_word_sop = FactoryBot.create(:doc_sop, policy: FactoryBot.create(:all_sysmo_downloadable_policy))
    pdf_path = ms_word_sop.content_blob.filepath('pdf')
    FileUtils.rm pdf_path if File.exist?(pdf_path)
    assert !File.exist?(pdf_path)
    assert ms_word_sop.can_download?

    get :get_pdf, params: { sop_id: ms_word_sop.id, id: ms_word_sop.content_blob.id }
    assert_response :success

    assert_equal "attachment; filename=\"ms_word_test.pdf\"; filename*=UTF-8''ms_word_test.pdf", @response.header['Content-Disposition']
    assert_equal 'application/pdf', @response.header['Content-Type']

    assert_includes 8000..9300, @response.header['Content-Length'].to_i, 'the content length should fall within the rage 8000-9300 bytes'

    assert File.exist?(ms_word_sop.content_blob.filepath)
    assert File.exist?(pdf_path)
  end

  test 'get_pdf from url' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/a_pdf_file.pdf",
                     'http://somewhere.com/piccy.pdf',
                     'Content-Type' => 'application/pdf',
                     'Content-Length' => 500
    pdf_sop = FactoryBot.create(:sop,
                      policy: FactoryBot.create(:all_sysmo_downloadable_policy),
                      content_blob: FactoryBot.create(:pdf_content_blob,
                                            data: nil,
                                            url: 'http://somewhere.com/piccy.pdf',
                                            uuid: UUID.generate))
    assert !pdf_sop.content_blob.file_exists?
    assert pdf_sop.content_blob.cachable?

    with_config_value(:hard_max_cachable_size, 10_000) do # Temporarily increase this, as the PDF is ~8kB
      get :get_pdf, params: { sop_id: pdf_sop.id, id: pdf_sop.content_blob.id }
    end

    assert_response :success

    assert_equal "attachment; filename=\"a_pdf_file.pdf\"; filename*=UTF-8''a_pdf_file.pdf", @response.header['Content-Disposition']
    assert_equal 'application/pdf', @response.header['Content-Type']
    assert_equal '8827', @response.header['Content-Length']

    assert File.exist?(pdf_sop.content_blob.filepath)
    assert !File.exist?(pdf_sop.content_blob.filepath('pdf')), "Shouldn't generate an separate PDF file, as it is already a PDF"
  end

  test 'get_pdf of a doc file from url' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/ms_word_test.doc",
                     'http://somewhere.com/piccy.doc',
                     'Content-Type' => 'application/pdf',
                     'Content-Length' => 500
    doc_sop = FactoryBot.create(:sop,
                      policy: FactoryBot.create(:all_sysmo_downloadable_policy),
                      content_blob: FactoryBot.create(:doc_content_blob,
                                            data: nil,
                                            url: 'http://somewhere.com/piccy.doc',
                                            uuid: UUID.generate))
    with_config_value(:hard_max_cachable_size, 10_000) do # Temporarily increase this, as the PDF is ~9kB
      get :get_pdf, params: { sop_id: doc_sop.id, id: doc_sop.content_blob.id }
    end
    assert_response :success
    assert_equal "attachment; filename=\"ms_word_test.pdf\"; filename*=UTF-8''ms_word_test.pdf", @response.header['Content-Disposition']
    assert_equal 'application/pdf', @response.header['Content-Type']
    assert_includes 8000..9300, @response.header['Content-Length'].to_i, 'the content length should fall within the rage 8000-9300 bytes'

    assert File.exist?(doc_sop.content_blob.filepath)
    assert File.exist?(doc_sop.content_blob.filepath('pdf')), 'the generated PDF file should remain'
  end



  test 'should gracefully handle view_pdf for non existing asset' do
    stub_request(:head, 'http://somewhere.com/piccy.doc').to_return(status: 404)
    sop = FactoryBot.create(:sop,
                  policy: FactoryBot.create(:all_sysmo_downloadable_policy),
                  content_blob: FactoryBot.create(:doc_content_blob,
                                        data: nil,
                                        url: 'http://somewhere.com/piccy.doc',
                                        uuid: UUID.generate))
    blob = sop.content_blob
    get :get_pdf, params: { sop_id: 999, id: blob.id }
    assert_redirected_to root_path
    assert_not_nil flash[:error]
  end

  test 'report error when file unavailable for download' do
    df = FactoryBot.create :data_file, policy: FactoryBot.create(:public_policy)
    df.content_blob.dump_data_to_file
    assert df.content_blob.file_exists?
    FileUtils.rm df.content_blob.filepath
    refute df.content_blob.file_exists?

    get :download, params: { data_file_id: df, id: df.content_blob }

    assert_redirected_to df
    assert flash[:error].match(/Unable to find a copy of the file for download/)
  end

  test 'get view content' do
    sop = FactoryBot.create(:pdf_sop, policy: FactoryBot.create(:all_sysmo_downloadable_policy))

    assert_difference('ActivityLog.count') do
      get :view_content, params: { sop_id: sop.id, id: sop.content_blob.id }
    end

    assert_response :success

    download_path = download_sop_content_blob_path(sop, sop.content_blob.id, format: :pdf, disposition: :inline, intent: :inline_view)
    assert @response.body.include?("DEFAULT_URL = '#{download_path}'")

    al = ActivityLog.last
    assert_equal 'inline_view', al.action
    assert_equal sop.content_blob, al.referenced
    assert_equal sop, al.activity_loggable
    assert_equal User.current_user, al.culprit
    assert_equal 'content_blobs', al.controller_name
  end

  test 'log inline_view for viewing pdf and image' do
    sop = FactoryBot.create(:pdf_sop, policy: FactoryBot.create(:all_sysmo_downloadable_policy))
    assert_difference('ActivityLog.count') do
      get :view_content, params: { sop_id: sop.id, id: sop.content_blob.id }
    end
    assert_response :success
    al = ActivityLog.last
    assert_equal 'inline_view', al.action

    df = FactoryBot.create(:data_file, policy: FactoryBot.create(:all_sysmo_downloadable_policy),
                             content_blob: FactoryBot.create(:image_content_blob,
                                                   original_filename: 'test.png',
                                                   content_type: 'image/png'))
    assert_difference('ActivityLog.count') do
      get :download, params: { data_file_id: df.id, id: df.content_blob.id, disposition: 'inline' }
    end
    assert_response :success
    al = ActivityLog.last
    assert_equal 'inline_view', al.action
  end

  test 'should view content as correct format for type' do
    df = FactoryBot.create(:data_file, content_blob: FactoryBot.create(:csv_content_blob), policy: FactoryBot.create(:all_sysmo_downloadable_policy))
    get :view_content, params: { data_file_id: df.id, id: df.content_blob.id }
    assert_response :success
    assert @response.body.include?('1,2,3,4,5')
    assert_equal 'text/plain', @response.media_type

    df = FactoryBot.create(:data_file, content_blob: FactoryBot.create(:doc_content_blob), policy: FactoryBot.create(:all_sysmo_downloadable_policy))
    get :view_content, params: { data_file_id: df.id, id: df.content_blob.id }
    assert_response :success
    assert_equal 'text/html', @response.media_type
  end

  test 'can fetch csv content blob as csv' do
    df = FactoryBot.create(:data_file, content_blob: FactoryBot.create(:csv_content_blob), policy: FactoryBot.create(:all_sysmo_downloadable_policy))
    get :show, params: { data_file_id: df.id, id: df.content_blob.id, format: 'csv' }
    assert_response :success

    assert @response.media_type, 'text/csv'

    csv = @response.body
    assert csv.include?(%(1,2,3,4,5))

  end

  test 'can fetch excel content blob as csv' do
    df = FactoryBot.create(:data_file, content_blob: FactoryBot.create(:sample_type_populated_template_content_blob), policy: FactoryBot.create(:all_sysmo_downloadable_policy))
    get :show, params: { data_file_id: df.id, id: df.content_blob.id, format: 'csv' }
    assert_response :success

    assert @response.media_type, 'text/csv'

    csv = @response.body
    assert csv.include?(%(,"some stuff"))

  end

  test 'cannot fetch binary content blob as csv' do
    df = FactoryBot.create(:data_file, content_blob: FactoryBot.create(:binary_content_blob), policy: FactoryBot.create(:all_sysmo_downloadable_policy))
    get :show, params: { data_file_id: df.id, id: df.content_blob.id, format: 'csv' }
    assert_response :not_acceptable

    assert @response.media_type, 'text/csv'

    csv = @response.body
    assert csv.include?(%(Unable to view))

  end

  test 'cannot fetch empty content blob as csv' do
    df = FactoryBot.create(:data_file, content_blob: FactoryBot.create(:blank_pdf_content_blob), policy: FactoryBot.create(:all_sysmo_downloadable_policy))
    get :show, params: { data_file_id: df.id, id: df.content_blob.id, format: 'csv' }
    assert_response :not_found

    assert @response.media_type, 'text/csv'

    csv = @response.body
    assert csv.include?(%(No content))

  end

  test 'can view content of an image file' do
    df = FactoryBot.create(:data_file, policy: FactoryBot.create(:all_sysmo_downloadable_policy),
                             content_blob: FactoryBot.create(:image_content_blob))

    get :download, params: { data_file_id: df.id, id: df.content_blob.id, disposition: 'inline', image_size: '900' }

    assert_response :success
    assert_equal ApplicationController::USER_CONTENT_CSP, @response.header['Content-Security-Policy']
  end

  test 'can view content of an image file and resize to given param' do
    df = FactoryBot.create(:data_file, policy: FactoryBot.create(:all_sysmo_downloadable_policy),
                             content_blob: FactoryBot.create(:image_content_blob))

    get :download, params: { data_file_id: df.id, id: df.content_blob.id, disposition: 'inline', image_size: '10' }

    assert_response :success
    assert_equal ApplicationController::USER_CONTENT_CSP, @response.header['Content-Security-Policy']
    assert @response.header['Content-Length'].to_i < 2000, 'Image should have been resized'
  end

  test 'can view content of an SVG image file without converting' do
    df = FactoryBot.create(:data_file, policy: FactoryBot.create(:all_sysmo_downloadable_policy),
                             content_blob: FactoryBot.create(:svg_content_blob))

    get :download, params: { data_file_id: df.id, id: df.content_blob.id, disposition: 'inline', image_size: '900' }

    assert_response :success
    assert_equal ApplicationController::USER_CONTENT_CSP, @response.header['Content-Security-Policy']
    assert_equal 'image/svg+xml', @response.header['Content-Type']
    assert  @response.body[0..256].include?('<svg ')
  end

  test 'should transparently redirect on download for 302 url' do
    mock_http
    df = FactoryBot.create :data_file,
                 policy: FactoryBot.create(:all_sysmo_downloadable_policy),
                 content_blob: FactoryBot.create(:url_content_blob,
                                       url: 'http://mocked302.com',
                                       uuid: UUID.generate)
    assert !df.content_blob.file_exists?

    get :download, params: { data_file_id: df, id: df.content_blob }
    assert_response :success
  end

  test 'should redirect on download for 401 url' do
    mock_http
    df = FactoryBot.create :data_file,
                 policy: FactoryBot.create(:all_sysmo_downloadable_policy),
                 content_blob: FactoryBot.create(:url_content_blob,
                                       url: 'http://mocked401.com',
                                       uuid: UUID.generate)
    assert !df.content_blob.file_exists?

    get :download, params: { data_file_id: df, id: df.content_blob }

    assert_redirected_to df.content_blob.url
  end

  test 'should download' do
    df = FactoryBot.create :small_test_spreadsheet_datafile, policy: FactoryBot.create(:public_policy), contributor: User.current_user.person
    assert_difference('ActivityLog.count') do
      get :download, params: { data_file_id: df, id: df.content_blob }
    end
    assert_response :success
    assert_equal "attachment; filename=\"small-test-spreadsheet.xls\"; filename*=UTF-8''small-test-spreadsheet.xls", @response.header['Content-Disposition']
    assert_equal 'application/vnd.ms-excel', @response.header['Content-Type']
    assert_equal '7168', @response.header['Content-Length']
    assert_equal '86f7a87eb0b1c30b172037d69628f279', @response.header['Content-MD5']
  end

  test 'download should provide the content length if file exists but has a url' do
    df = FactoryBot.create :small_test_spreadsheet_datafile, policy: FactoryBot.create(:public_policy), contributor: User.current_user.person
    blob = df.content_blob
    blob.update_column(:url, 'http://website.com/somefile.txt')
    get :download, params: { data_file_id: df, id: df.content_blob }
    assert_response :success
    assert_equal "attachment; filename=\"small-test-spreadsheet.xls\"; filename*=UTF-8''small-test-spreadsheet.xls", @response.header['Content-Disposition']
    assert_equal 'application/vnd.ms-excel', @response.header['Content-Type']
    assert_equal '7168', @response.header['Content-Length']
    assert_equal '86f7a87eb0b1c30b172037d69628f279', @response.header['Content-MD5']
  end

  test 'download via streaming should provide the content length' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/ms_word_test.doc",
                     'http://somewhere.com/piccy.doc',
                     'Content-Length':'500'
    doc_sop = FactoryBot.create(:sop,
                      policy: FactoryBot.create(:public_policy),
                      contributor: User.current_user.person,
                      content_blob: FactoryBot.create(:doc_content_blob,
                                            data: nil,
                                            url: 'http://somewhere.com/piccy.doc',
                                            uuid: UUID.generate))
    get :download, params: { sop_id: doc_sop, id: doc_sop.content_blob }
    assert_response :success

    assert_equal '500', @response.header['Content-Length']
  end


  test 'should not log download for inline view intent' do
    df = FactoryBot.create :small_test_spreadsheet_datafile, policy: FactoryBot.create(:public_policy), contributor: User.current_user.person
    assert_no_difference('ActivityLog.count') do
      get :download, params: { data_file_id: df, id: df.content_blob, intent: :inline_view }
    end
    assert_response :success
  end

  test 'should download from url' do
    mock_http
    df = FactoryBot.create :data_file,
                 policy: FactoryBot.create(:all_sysmo_downloadable_policy),
                 content_blob: FactoryBot.create(:url_content_blob,
                                       url: 'http://mockedlocation.com/a-piccy.png',
                                       uuid: UUID.generate)
    assert_difference('ActivityLog.count') do
      get :download, params: { data_file_id: df, id: df.content_blob }
    end
    assert_response :success
  end

  test 'should gracefully handle when downloading a unknown host url' do
    mock_http
    df = FactoryBot.create :data_file,
                 policy: FactoryBot.create(:all_sysmo_downloadable_policy),
                 content_blob: FactoryBot.create(:url_content_blob,
                                       url: 'http://unknownhost.com/pic.png',
                                       uuid: UUID.generate)

    get :download, params: { data_file_id: df, id: df.content_blob }

    assert_redirected_to data_file_path(df, version: df.version)
    assert_not_nil flash[:error]
  end

  test 'should gracefully handle when downloading a url resulting in 404' do
    mock_http
    df = FactoryBot.create :data_file,
                 policy: FactoryBot.create(:all_sysmo_downloadable_policy),
                 content_blob: FactoryBot.create(:url_content_blob,
                                       url: 'http://mocked404.com',
                                       uuid: UUID.generate)

    get :download, params: { data_file_id: df, id: df.content_blob }
    assert_redirected_to data_file_path(df, version: df.version)
    assert_not_nil flash[:error]
  end

  test 'should gracefully handle other error codes' do
    mock_http
    df = FactoryBot.create :data_file,
                 policy: FactoryBot.create(:all_sysmo_downloadable_policy),
                 content_blob: FactoryBot.create(:url_content_blob,
                                       url: 'http://mocked500.com',
                                       uuid: UUID.generate)

    get :download, params: { data_file_id: df, id: df.content_blob }
    assert_redirected_to data_file_path(df, version: df.version)
    assert_not_nil flash[:error]
    assert_includes flash[:error], '500'
  end

  test 'should handle inline download when specify the inline disposition' do
    data = File.new("#{Rails.root}/test/fixtures/files/file_picture.png", 'rb').read
    df = FactoryBot.create :data_file,
                 content_blob: FactoryBot.create(:content_blob, data: data, content_type: 'images/png'),
                 policy: FactoryBot.create(:downloadable_public_policy)

    get :download, params: { data_file_id: df, id: df.content_blob, disposition: 'inline' }
    assert_response :success
    assert @response.header['Content-Disposition'].include?('inline')
  end



  test 'should handle normal attachment download' do
    data = File.new("#{Rails.root}/test/fixtures/files/file_picture.png", 'rb').read
    df = FactoryBot.create :data_file,
                 content_blob: FactoryBot.create(:content_blob, data: data, content_type: 'images/png'),
                 policy: FactoryBot.create(:downloadable_public_policy)

    get :download, params: { data_file_id: df, id: df.content_blob }
    assert_response :success
    assert @response.header['Content-Disposition'].include?('attachment')
  end

  test 'activity correctly logged' do
    model = FactoryBot.create :model_2_files, policy: FactoryBot.create(:public_policy), contributor: User.current_user.person
    first_content_blob = model.content_blobs.first
    assert_difference('ActivityLog.count') do
      get :download, params: { model_id: model.id, id: first_content_blob.id }
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
    model = FactoryBot.create :model_2_files, policy: FactoryBot.create(:public_policy), contributor: User.current_user.person
    first_content_blob = model.content_blobs.first
    assert_difference('ActivityLog.count') do
      get :download, params: { model_id: model.id, id: first_content_blob.id }
    end
    assert_response :success
    assert_equal "attachment; filename=\"#{first_content_blob.original_filename}\"; filename*=UTF-8''#{first_content_blob.original_filename}", @response.header['Content-Disposition']
    assert_equal first_content_blob.content_type, @response.header['Content-Type']
    assert_equal first_content_blob.file_size.to_s, @response.header['Content-Length']
  end

  test 'should not download private data if url manipulated' do
    id = [Sop.last.id, DataFile.last.id].max + 1
    sop = FactoryBot.create(:sop, id: id, policy: FactoryBot.create(:public_policy),
                        content_blob: FactoryBot.create(:txt_content_blob, data: 'public'))
    data_file = FactoryBot.create(:data_file, id: id, policy: FactoryBot.create(:private_policy),
                                    content_blob: FactoryBot.create(:txt_content_blob, data: 'secret'))

    assert_equal sop.id, data_file.id
    assert sop.can_download?
    refute data_file.can_download?

    get :download, params: { sop_id: sop.id, id: data_file.content_blob.id }
    assert_not_equal 'secret', response.body.force_encoding(Encoding::UTF_8)
    assert_response :redirect

    get :download, params: { sop_id: sop.id, id: data_file.content_blob.id, format: 'json' }
    assert_response :not_found
  end

  test 'download sample type template blob' do
    person = User.current_user.person
    sample_type = FactoryBot.create(:strain_sample_type, contributor:person)
    refute_nil sample_type.template
    assert sample_type.can_view?
    assert sample_type.can_download?
    assert_difference('ActivityLog.count') do
      get :download, params: { sample_type_id:sample_type.id, id:sample_type.template.id }
    end

    assert_response :success
    assert_equal "attachment; filename=\"#{sample_type.template.original_filename}\"; filename*=UTF-8''#{sample_type.template.original_filename}", @response.header['Content-Disposition']

    assert_equal sample_type, ActivityLog.last.activity_loggable
    assert_equal 'download',ActivityLog.last.action
  end

  test 'cannot download sample type template you cannot view' do
    login_as(FactoryBot.create(:person))
    sample_type = FactoryBot.create(:strain_sample_type, contributor:FactoryBot.create(:person))
    refute_nil sample_type.template
    refute sample_type.can_view?
    refute sample_type.can_download?
    assert_no_difference('ActivityLog.count') do
      get :download, params: { sample_type_id:sample_type.id, id:sample_type.template.id }
    end

    assert_response :redirect
  end

  test 'should view content for pdf blob' do
    sop = FactoryBot.create(:public_sop)
    blob = FactoryBot.create(:pdf_content_blob, asset: sop)

    get :view_content, params: { sop_id: sop.id, id: blob.id }

    assert_response :success
    assert @response.header['Content-Type'].start_with?('text/html')
    assert_nil @response.header['Content-Security-Policy']
    assert_select 'iframe', count: 0
    assert_select '#outerContainer'
  end

  test 'should view content for markdown blob' do
    sop = FactoryBot.create(:public_sop)
    blob = FactoryBot.create(:markdown_content_blob, asset: sop)

    get :view_content, params: { sop_id: sop.id, id: blob.id }

    assert_response :success
    assert @response.header['Content-Type'].start_with?('text/html')
    assert_equal ApplicationController::USER_CONTENT_CSP, @response.header['Content-Security-Policy']
    assert_select 'iframe', count: 0
    assert_select '#navbar', count: 0
    assert_select '.markdown-body h1', text: 'FAIRDOM-SEEK'
  end

  test 'should view content for jupyter blob renderer' do
    sop = FactoryBot.create(:public_sop)
    blob = FactoryBot.create(:jupyter_notebook_content_blob, asset: sop)

    get :view_content, params: { sop_id: sop.id, id: blob.id }

    assert_response :success
    assert @response.header['Content-Type'].start_with?('text/html')
    assert_equal "default-src 'self'; img-src * data:; style-src 'unsafe-inline';", @response.header['Content-Security-Policy']
    assert_select 'iframe', count: 0
    assert_select '#navbar', count: 0
    assert_select 'body.jp-Notebook'
    assert_select 'div.jp-MarkdownOutput p', text: 'Import the libraries so that they can be used within the notebook'
  end

  test 'should view content for text blob' do
    sop = FactoryBot.create(:public_sop)
    blob = FactoryBot.create(:txt_content_blob, asset: sop)

    get :view_content, params: { sop_id: sop.id, id: blob.id }

    assert_response :success
    assert @response.header['Content-Type'].start_with?('text/plain')
    assert_equal ApplicationController::USER_CONTENT_CSP, @response.header['Content-Security-Policy']
    assert_equal "This is a txt format\n", response.body
  end

  test 'should view content for image blob' do
    sop = FactoryBot.create(:public_sop)
    blob = FactoryBot.create(:image_content_blob, asset: sop)

    get :view_content, params: { sop_id: sop.id, id: blob.id }

    assert_response :success
    assert @response.header['Content-Type'].start_with?('text/html')
    assert_equal ApplicationController::USER_CONTENT_CSP, @response.header['Content-Security-Policy']
    assert_select 'img.git-image-preview[src=?]', download_sop_content_blob_path(sop, blob, disposition: 'inline')
  end

  test 'should view content for jupyter blob as text if requested' do
    sop = FactoryBot.create(:public_sop)
    blob = FactoryBot.create(:jupyter_notebook_content_blob, asset: sop)

    get :view_content, params: { sop_id: sop.id, id: blob.id, display: 'text' }

    assert_response :success
    assert @response.header['Content-Type'].start_with?('text/plain')
    assert_equal ApplicationController::USER_CONTENT_CSP, @response.header['Content-Security-Policy']
    assert response.body[0..20].include?('"nbformat": 4')
  end

  test 'should through 406 if trying to view content for pdf blob as text' do
    sop = FactoryBot.create(:public_sop)
    blob = FactoryBot.create(:pdf_content_blob, asset: sop)

    assert_raises(ActionController::UnknownFormat) do
      get :view_content, params: { sop_id: sop.id, id: blob.id, display: 'text' }
    end
  end

  test 'examine url with redirect' do
    stub_request(:head, 'http://website.com/file.pdf').to_return(status: 302, headers: { 'Location' => 'https://website.com/file.pdf' })
    stub_request(:head, 'https://website.com/file.pdf').to_return(status: 200, headers: { 'Content-Type' => 'application/pdf' })
    stub_request(:get, 'http://website.com/file.pdf').to_return(status: 302, headers: { 'Content-Type' => 'application/pdf' })
    get :examine_url, xhr: true, params: { data_url: 'http://website.com/file.pdf' }
    assert_response 200
    assert_equal 200, assigns(:info)[:code]
    assert_equal 'application/pdf', assigns(:info)[:content_type]
    assert_equal 'file.pdf', assigns(:info)[:file_name]
  end

  test 'examine url with redirect to 403' do
    stub_request(:head, 'http://unauth.com/file.pdf').to_return(status: 302, headers: { 'Location' => 'https://unauth.com/file.pdf' })
    stub_request(:head, 'https://unauth.com/file.pdf').to_return(status: 403, headers: { 'Content-Type' => 'application/pdf' })
    stub_request(:get, 'http://unauth.com/file.pdf').to_return(status: 302, headers: { 'Location' => 'https://unauth.com/file.pdf' })
    stub_request(:get, 'https://unauth.com/file.pdf').to_return(status: 403, headers: { 'Content-Type' => 'application/pdf' })
    get :examine_url, xhr: true, params: { data_url: 'http://unauth.com/file.pdf' }
    assert_response 200
    assert_equal 403, assigns(:info)[:code]
    assert_equal 'application/pdf', assigns(:info)[:content_type]
    assert_equal 'file.pdf', assigns(:info)[:file_name]
    assert @response.body.include?('Access to this link is unauthorized')
    assert_equal 'warning', assigns(:type)
    assert assigns(:warning_msg)
  end

  test 'examine url with redirect to 403 preserves content type' do
    stub_request(:head, 'http://unauth.com/some/path').to_return(status: 302, headers: { 'Location' => 'https://unauth.com/some/path' })
    stub_request(:head, 'https://unauth.com/some/path').to_return(status: 403, headers: { 'Content-Type' => 'text/html' })
    stub_request(:get, 'http://unauth.com/some/path').to_return(status: 302, headers: { 'Location' => 'https://unauth.com/some/path' })
    stub_request(:get, 'https://unauth.com/some/path').to_return(status: 403, headers: { 'Content-Type' => 'text/html' })
    get :examine_url, xhr: true, params: { data_url: 'http://unauth.com/some/path' }
    assert_response 200
    assert_equal 403, assigns(:info)[:code]
    assert_equal 'text/html', assigns(:info)[:content_type]
    assert_equal 'path', assigns(:info)[:file_name]
    assert @response.body.include?('Access to this link is unauthorized')
    assert_equal 'warning', assigns(:type)
    assert assigns(:warning_msg)
  end

  private

  def mock_http
    file = "#{Rails.root}/test/fixtures/files/file_picture.png"
    stub_request(:get, 'http://mockedlocation.com/a-piccy.png').to_return(body: File.new(file), status: 200, headers: { 'Content-Type' => 'image/png' })
    stub_request(:head, 'http://mockedlocation.com/a-piccy.png')

    stub_request(:any, 'http://mocked302.com').to_return(status: 302, headers: { location: 'http://www.mocked302.com' })
    stub_request(:any, 'http://www.mocked302.com').to_return(status: 200)
    stub_request(:any, 'http://mocked401.com').to_return(status: 401)
    stub_request(:any, 'http://mocked404.com').to_return(status: 404)
    stub_request(:any, 'http://mocked500.com').to_return(status: 500)

    stub_request(:any, 'http://unknownhost.com/pic.png').to_raise(SocketError)
  end
end
