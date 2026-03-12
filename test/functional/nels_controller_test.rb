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
    assert_select 'p#user-info',text:/Logged in as Finn Bacall/
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
    assay = FactoryBot.create(:assay)
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
    person = FactoryBot.create(:person)
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
      VCR.use_cassette('nels/get_project') do
        get :datasets, params: { assay_id: @assay.id, format: :json, id: @project_id }
      end
    end

    assert_response :success
    # 2 datasets, 6 subtypes (3 each)
    assert_equal 8, JSON.parse(response.body).length
  end

  test 'can load dataset' do
    VCR.use_cassette('nels/get_dataset') do
      VCR.use_cassette('nels/check_metadata_exists') do
        VCR.use_cassette('nels/get_project') do
          get :dataset, params: { project_id: @project_id, dataset_id: @dataset_id }
        end
      end
    end

    assert_response :success
    assert_select 'li.list-group-item', count: 2
  end

  test 'locked dataset doesnt disable add metadata' do
    VCR.use_cassette('nels/get_locked_dataset') do
      VCR.use_cassette('nels/check_metadata_exists') do
        VCR.use_cassette('nels/get_project') do
          get :dataset, params: { project_id: @project_id, dataset_id: @dataset_id }
        end
      end
    end

    assert_response :success
    assert_select 'a.add_metadata', count: 2
    assert_select 'a.add_metadata.disabled', count: 0
  end

  test 'get subtype in locked dataset' do
    VCR.use_cassette('nels/get_dataset') do
      VCR.use_cassette('nels/check_metadata_exists') do
        VCR.use_cassette('nels/get_locked_project') do
          VCR.use_cassette('nels/sbi_storage_list') do
            get :subtype,
                params: { project_id: @project_id, dataset_id: @dataset_id, subtype: 'reads',
                          path: 'Storebioinfo/seek_pilot3/Demo Dataset/reads/' }
          end
        end
      end
    end

    assert_response :success
    assert_select 'a.upload_file.disabled'
    assert_select 'a.add_metadata'
    assert_select 'a.add_metadata.disabled', count: 0

    # locked icon next to the dataset name
    assert_select 'a[data-tree-node-id=dataset91123528] ~ span.glyphicon-lock'
  end

  test 'get subtype' do
    VCR.use_cassette('nels/get_dataset') do
      VCR.use_cassette('nels/check_metadata_exists') do
        VCR.use_cassette('nels/get_project') do
          VCR.use_cassette('nels/sbi_storage_list') do
            get :subtype,
                params: { project_id: @project_id, dataset_id: @dataset_id, subtype: 'reads',
                          path: 'Storebioinfo/seek_pilot3/Demo Dataset/reads/' }
          end
        end
      end
    end

    assert_response :success
    assert_select 'a.upload_file'
    assert_select 'a.upload_file.disabled', count: 0
    assert_select 'a.add_metadata'
    assert_select 'a.add_metadata.disabled', count: 0

    assert_select 'table tr td span.nels-folder', count: 5
    assert_select 'table tr td a.nels-download-link', count: 2

    # locked icon next to the dataset name shouldn't be present
    assert_select 'a[data-tree-node-id=dataset91123528] ~ span.glyphicon-lock', count: 0
  end

  test 'can register data' do
    @assay.investigation.projects << FactoryBot.create(:project)
    project_ids = @assay.reload.project_ids

    assert_no_difference('DataFile.count') do
      assert_difference('ContentBlob.count', 1) do
        VCR.use_cassette('nels/get_dataset') do
          VCR.use_cassette('nels/get_persistent_url') do
            post :register,
                 params: { assay_id: @assay.id, project_id: @project_id, dataset_id: @dataset_id,
                           subtype_name: @subtype }

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
    dataset_name = 'Illumina-sequencing-dataset'
    project_name = 'seek_pilot1'
    subtype = 'analysis'
    path = 'Storebioinfo/seek_pilot1/Illumina-sequencing-dataset/anaylsis'

    VCR.use_cassette('nels/download_file') do
      get :download_file,
          params: { dataset_id: dataset_id, project_id: project_id,
                    subtype_name: subtype, dataset_name: dataset_name, project_name: project_name,
                    path: path, filename: 'pegion.png' },
          format: :json
      assert_response :success
      json = JSON.parse(@response.body)
      assert_equal 'pegion.png', json['filename']
      refute_nil json['file_key']
      path = "/tmp/nels-download-#{json['file_key']}"
      assert File.exist?(path)
      File.delete(path)
    end
  end

  test 'fetch file valid key' do
    key = UUID.generate
    path = "/tmp/nels-download-#{key}"
    file = File.new(path, 'wb')
    file.write('wibble')
    file.close
    assert File.exist?(path)
    get :fetch_file, params: {filename:'wibble.txt', file_key: key}
    assert_response :success
    assert_equal 'wibble', @response.body
    assert_equal "attachment; filename=\"wibble.txt\"; filename*=UTF-8''wibble.txt", @response.header['Content-Disposition']
    refute File.exist?(path)
  end

  test 'fetch file missing file' do
    key = UUID.generate

    assert_raises Nels::Rest::Client::FetchFileError, match: /temp copy of file doesnt exist/ do
      get :fetch_file, params: {filename:'wibble.txt', file_key: key}
    end
  end

  test 'fetch file invalid key' do
    key = '18b6dbe0/../etc/passwd'

    assert_raises Nels::Rest::Client::FetchFileError, match: /Invalid file key/ do
      get :fetch_file, params: {filename:'wibble.txt', file_key: key}
    end
  end

  test 'upload file' do
    project_id = '1125299'
    dataset_id = '1124840'
    subtype = 'analysis'

    file_path = File.join(Rails.root, 'test', 'fixtures', 'files', 'little_file.txt')
    assert File.exist?(file_path)

    file_data = fixture_file_upload('little_file.txt', 'text/plain')

    VCR.use_cassette('nels/upload_file') do
      post :upload_file,
           params: { dataset_id: dataset_id, project_id: project_id, subtype_name: subtype,
                     subtype_path: '', content_blobs: [{ data: file_data }] }, format: :json
      assert_response :success
      assert_equal true, JSON.parse(response.body)['success']
    end
  end

  test 'upload file not authorized error' do
    project_id = '1125299'
    dataset_id = '1124840'
    subtype = 'analysis'

    file_path = File.join(Rails.root, 'test', 'fixtures', 'files', 'little_file.txt')
    assert File.exist?(file_path)

    file_data = fixture_file_upload('little_file.txt', 'text/plain')

    VCR.use_cassette('nels/upload_file_401_error') do
      post :upload_file,
           params: { dataset_id: dataset_id, project_id: project_id, subtype_name: subtype,
                     subtype_path: '', content_blobs: [{ data: file_data }] }, format: :json
      assert_response :unauthorized
      assert_equal 'Unauthorized', JSON.parse(response.body)['error']
    end
  end

  test 'upload file method not allowed error' do
    project_id = '1125299'
    dataset_id = '1124840'
    subtype = 'analysis'

    file_path = File.join(Rails.root, 'test', 'fixtures', 'files', 'little_file.txt')
    assert File.exist?(file_path)

    file_data = fixture_file_upload('little_file.txt', 'text/plain')

    VCR.use_cassette('nels/upload_file_405_error') do
      post :upload_file,
           params: { dataset_id: dataset_id, project_id: project_id, subtype_name: subtype,
                     subtype_path: '', content_blobs: [{ data: file_data }] }, format: :json
      assert_response :internal_server_error
      assert_equal 'Error interacting with the NeLS API (status: 405)', JSON.parse(response.body)['message']
    end
  end

  test 'upload file with space in name fails fails' do
    project_id = '1125299'
    dataset_id = '1124840'
    subtype = 'analysis'

    file_path = File.join(Rails.root, 'test', 'fixtures', 'files', 'file with spaces in name.txt')
    assert File.exist?(file_path)

    file_data = fixture_file_upload('file with spaces in name.txt', 'text/plain')

    post :upload_file,
         params: { dataset_id: dataset_id, project_id: project_id, subtype_name: subtype,
                   subtype_path: '', content_blobs: [{ data: file_data }] }, format: :json
    assert_response :not_acceptable
    assert_equal 'Filenames containing spaces are not allowed', JSON.parse(response.body)['error']
  end

  test 'create folder' do
    project_id = '1125299'
    dataset_id = '1125261'
    current_path = 'Storebioinfo/seek_pilot3/Demo Dataset/Analysis/'
    new_folder = 'test'
    VCR.use_cassette('nels/sbi_storage_list_create_folder') do
      post :create_folder,
           params: {
             project_id: project_id,
             dataset_id: dataset_id,
             file_path: current_path,
             new_folder: new_folder
           },
           format: :json
    end
    assert_response :success
    assert_equal true, JSON.parse(response.body)['success']
  end

  test 'create folder with spaces fails' do
    project_id = '1125299'
    dataset_id = '1125261'
    current_path = 'Storebioinfo/seek_pilot3/Demo Dataset/Analysis/'
    new_folder = 'test folder'
    VCR.use_cassette('nels/sbi_storage_list_create_folder') do
      post :create_folder,
           params: {
             project_id: project_id,
             dataset_id: dataset_id,
             file_path: current_path,
             new_folder: new_folder
           },
           format: :json
    end
    assert_response :not_acceptable
    assert_equal 'Folder names containing spaces are not allowed', JSON.parse(response.body)['error']
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

  test 'create dataset' do
    project_id = '1125299'
    datasettypeid = '225'
    name = 'test dataset'
    description = 'testing creating a dataset'

    VCR.use_cassette('nels/create_dataset') do
      VCR.use_cassette('nels/get_user_info') do
        post :create_dataset,
             params: { project: project_id, datasettype: datasettypeid, name: name, description: description }
      end
    end
    assert_response :success
  end
end
