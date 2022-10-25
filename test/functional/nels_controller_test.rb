require 'test_helper'

class NelsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  include NelsTestHelper

  setup do
    setup_nels
  end

  test 'can get browser' do
    VCR.use_cassette('nels/get_user_info') do
      get :index, params: { assay_id: @assay.id }
    end

    assert_response :success
    assert_select '#nels-tree'
  end

  test 'cannot get browser if nels disabled' do
    with_config_value(:nels_enabled, false) do
      VCR.use_cassette('nels/get_user_info') do
        get :index, params: { assay_id: @assay.id }
      end
    end

    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test 'cannot get browser for non-NeLS project assay' do
    assay = Factory(:assay)
    person = assay.contributor
    login_as(person)

    assert assay.can_edit?(person)
    refute assay.projects.any? { |p| p.settings.get('nels_enabled') }

    VCR.use_cassette('nels/get_user_info') do
      get :index, params: { assay_id: assay.id }
    end

    assert_redirected_to assay
    assert flash[:error].include?('NeLS-enabled')
  end

  test 'cannot get browser if NeLS integration disabled' do
    assert @assay.can_edit?(@user)
    assert @assay.projects.any? { |p| p.settings.get('nels_enabled') }

    with_config_value(:nels_enabled, false) do
      get :index, params: { assay_id: @assay.id }
    end

    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test 'cannot get browser for assay without edit permissions' do
    person = Factory(:person)
    login_as(person)

    refute @assay.can_edit?(person)
    assert @assay.projects.any? { |p| p.settings.get('nels_enabled') }

    VCR.use_cassette('nels/get_user_info') do
      get :index, params: { assay_id: @assay.id }
    end

    assert_redirected_to @assay
    assert flash[:error].include?('authorized')
  end

  test 'redirects to NeLS login if token expired' do
    session = @user.oauth_sessions.where(provider: 'NeLS').last
    session.update_column(:expires_at, 1.day.ago)
    oauth_client = Nels::Oauth2::Client.new(Seek::Config.nels_client_id,
                                            Seek::Config.nels_client_secret,
                                            nels_oauth_callback_url,
                                            "assay_id:#{@assay.id}")

    VCR.use_cassette('nels/get_user_info') do
      get :index, params: { assay_id: @assay.id }
    end

    assert_redirected_to oauth_client.authorize_url
  end

  test 'can load projects' do
    VCR.use_cassette('nels/get_projects') do
      get :projects, params: { assay_id: @assay.id, format: :json }
    end

    assert_response :success
    assert_equal 2, JSON.parse(response.body).length
  end

  test 'reports 500 error when loading projects' do
    VCR.use_cassette('nels/get_projects_500') do
      get :projects, params: { assay_id: @assay.id, format: :json }
    end

    assert_response :internal_server_error
    assert_equal 'NeLS API Error', JSON.parse(response.body)['error']
  end

  test 'can load datasets' do
    VCR.use_cassette('nels/get_datasets') do
      get :datasets, params: { assay_id: @assay.id, format: :json, id: @project_id }
    end

    assert_response :success
    # 2 datasets, 6 subtypes (3 each)
    assert_equal 8, JSON.parse(response.body).length
  end

  test 'can load dataset' do
    VCR.use_cassette('nels/get_dataset') do
      VCR.use_cassette('nels/check_metadata_exists') do
        get :dataset, params: { assay_id: @assay.id, project_id: @project_id, dataset_id: @dataset_id }
      end
    end

    assert_response :success
    assert_select 'li.list-group-item', count: 2
  end

  test 'can register data' do
    @assay.investigation.projects << Factory(:project)
    project_ids = @assay.reload.project_ids

    assert_no_difference('DataFile.count') do
      assert_difference('ContentBlob.count', 1) do
        VCR.use_cassette('nels/get_dataset') do
          VCR.use_cassette('nels/get_persistent_url') do
            post :register, params: { assay_id: @assay.id, project_id: @project_id, dataset_id: @dataset_id, subtype_name: @subtype }

            assert_redirected_to provide_metadata_data_files_path(project_ids: project_ids)

            assert_equal 'https://test-fe.cbu.uib.no/nels/pages/sbi/sbi.xhtml?ref=xMTEyMzEyMjoxMTIzNTI4OnJlYWRz',
                         assigns(:data_file).content_blob.url
          end
        end
      end
    end
  end

  test 'download file' do
    project_id = '1125299'
    dataset_id = '1124840'
    subtype = 'analysis'


    VCR.use_cassette('nels/download_file') do
      get :download_file, params: { dataset_id: dataset_id, project_id: project_id, subtype_name: subtype, filename: 'pegion.png'}
      assert_response :success
      assert_equal 94353, @response.body.length
    end
  end

  test 'upload file' do
    project_id = '1125299'
    dataset_id = '1124840'
    subtype = 'analysis'

    file_path = File.join(Rails.root, 'test','fixtures','files','little_file.txt')
    assert File.exist?(file_path)

    file_data = fixture_file_upload('little_file.txt', 'text/plain')

    VCR.use_cassette('nels/upload_file') do
      post :upload_file, params:{ dataset_id: dataset_id, project_id: project_id, subtype_name: subtype, content_blobs: [{ data: file_data }]}
      assert_response :success
    end
  end

  test 'raises error on NeLS callback if no code provided' do
    get :callback

    assert_redirected_to root_path
    assert flash[:error].present?
  end

  test 'raises error on NeLS callback if no user logged-in' do
    logout

    get :callback, params: { code: '123' }

    assert_redirected_to root_path
    assert flash[:error].present?
  end
end
