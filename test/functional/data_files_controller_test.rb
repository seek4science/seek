
require 'test_helper'
require 'libxml'
require 'openbis_test_helper'

class DataFilesControllerTest < ActionController::TestCase

  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases
  include RdfTestCases
  include SharingFormTestHelper
  include GeneralAuthorizationTestCases
  include MockHelper
  include NelsTestHelper

  def setup
    login_as(:datafile_owner)
  end

  def rest_api_test_object
    # by TZ for some reason depending on tets order user was no longer logged
    login_as(:datafile_owner) unless User.current_user
    @object = data_files(:picture)
    @object.annotate_with 'tag1'
    @object
  end

  def test_title
    get :index
    assert_response :success
    assert_select 'title', text: 'Data files', count: 1

    df = Factory(:data_file, contributor: User.current_user.person)
    get :show, params: { id: df }
    assert_response :success
    assert_select 'title', text: df.title, count: 1

  end

  test 'json link includes version' do
    df = Factory(:data_file, policy: Factory(:public_policy))
    test_show_json(df)
    json = JSON.parse(response.body)
    refute_nil json['data']
    refute_nil json['data']['links']
    refute_nil json['data']['links']['self']
    assert json['data']['links']['self'].ends_with?("?version=#{df.version}")
  end

  # because the activity logging is currently an after_action, the AuthorizationEnforcement can silently prevent
  # the log being saved, unless it is public, since it has passed out of the around filter and User.current_user is nil
  test 'download and view activity logging for private items' do
    df = Factory :data_file, policy: Factory(:private_policy)
    @request.session[:user_id] = df.contributor.user.id
    assert_difference('ActivityLog.count') do
      get :show, params: { id: df }
    end
    assert_response :success

    al = ActivityLog.order(:id).last
    assert_equal 'show', al.action
    assert_equal df, al.activity_loggable

    assert_difference('ActivityLog.count') do
      get :download, params: { id: df }
    end
    assert_response :success

    al = ActivityLog.order(:id).last
    assert_equal 'download', al.action
    assert_equal df, al.activity_loggable
  end

  test 'correct title and text for associating an assay for new' do
    login_as(Factory(:user))
    as_not_virtualliver do
      register_content_blob
      assert_response :success
      assert_select 'div.association_step p', text: /You may select an existing editable #{I18n.t('assays.experimental_assay')} or #{I18n.t('assays.modelling_analysis')} to associate with this #{I18n.t('data_file')}./
    end

    assert_select 'div.panel-heading', text: /#{I18n.t('assays.experimental_assay').pluralize} and #{I18n.t('assays.modelling_analysis').pluralize}/
    assert_select 'div#associate_assay_fold_content p', text: /The following #{I18n.t('assays.experimental_assay').pluralize} and #{I18n.t('assays.modelling_analysis').pluralize} are associated with this #{I18n.t('data_file')}:/
  end

  test 'correct title and text for associating an assay for edit' do
    df = Factory :data_file
    login_as(df.contributor.user)
    as_not_virtualliver do
      get :edit, params: { id: df.id }
      assert_response :success
      assert_select 'div.association_step p', text: /You may select an existing editable #{I18n.t('assays.experimental_assay')} or #{I18n.t('assays.modelling_analysis')} to associate with this #{I18n.t('data_file')}./
    end

    assert_select 'div.panel-heading', text: /#{I18n.t('assays.experimental_assay').pluralize} and #{I18n.t('assays.modelling_analysis').pluralize}/
    assert_select 'div#associate_assay_fold_content p', text: /The following #{I18n.t('assays.experimental_assay').pluralize} and #{I18n.t('assays.modelling_analysis').pluralize} are associated with this #{I18n.t('data_file')}:/
  end

  test 'should show index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:data_files)
  end

  test 'should show index for non project member, should show for non login user' do
    login_as(:registered_user_with_no_projects)
    get :index
    assert_response :success

    logout
    get :index
    assert_response :success
    assert_not_nil assigns(:data_files)
  end

  test 'creators show in list private_item' do
    p1 = Factory :person
    p2 = Factory :person
    df = Factory(:data_file, title: 'ZZZZZ', creators: [p2], contributor: p1, policy: Factory(:public_policy, access_type: Policy::VISIBLE))

    get :index, params: { page: 'Z' }

    # check the test is behaving as expected:
    assert_equal p1, df.contributor
    assert df.creators.include?(p2)
    assert_select '.list_item_title a[href=?]', data_file_path(df), 'ZZZZZ', 'the data file for this test should appear as a list private_item'

    # check for avatars
    assert_select '.list_item_avatar' do
      assert_select 'a[href=?]', person_path(p2) do
        assert_select 'img'
      end
    end
  end

  test 'non project member and non login user cannot edit datafile with public policy and editable' do
    login_as(:registered_user_with_no_projects)
    data_file = Factory(:data_file, policy: Factory(:public_policy, access_type: Policy::EDITING))

    put :update, params: { id: data_file, data_file: { title: 'new title' } }

    assert_response :redirect
  end

  test 'associates assay' do
    login_as(:model_owner) # can edit assay
    d = data_files(:picture)
    original_assay = assays(:metabolomics_assay)

    assert_includes original_assay.data_files, d

    new_assay = assays(:metabolomics_assay2)

    refute_includes new_assay.data_files, d
    assert_difference('ActivityLog.count') do
      put :update, params: { id: d, data_file: { title: d.title, assay_assets_attributes: [{ assay_id: new_assay.id.to_s }] } }
    end

    assert_redirected_to data_file_path(d)
    d.reload
    original_assay.reload
    new_assay.reload

    refute_includes original_assay.data_files, d
    assert_includes new_assay.data_files, d
  end

  test "shouldn't show hidden items in index" do
    login_as(:aaron)
    get :index, params: { page: 'all' }
    assert_response :success
    assert_equal assigns(:data_files).sort_by(&:id),
                 assigns(:data_files).authorized_for('view', users(:aaron)).sort_by(&:id), "data files haven't been authorized properly"
  end

  test 'should get new' do
    get :new
    assert_response :success
    assert_select 'h1', text: "New #{I18n.t('data_file')}"
  end

  test 'should correctly handle bad data url' do
    stub_request(:head, 'http://sdfsdfds.com/sdf.png')
      .to_raise(SocketError)
    df = { title: 'Test', project_ids: [projects(:sysmo_project).id] }
    blob = { data_url: 'http://sdfsdfds.com/sdf.png' }
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('DataFile.count') do
        assert_no_difference('ContentBlob.count') do
          post :create, params: { data_file: df, content_blobs: [blob], policy_attributes: valid_sharing }
        end
      end
    end

    assert_not_nil flash.now[:error]
  end

  test 'should not create invalid datafile' do
    df = { title: 'Test' }
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('DataFile.count') do
        assert_no_difference('ContentBlob.count') do
          post :create, params: { data_file: df, content_blobs: [{}], policy_attributes: valid_sharing }
        end
      end
    end

    assert_not_nil flash.now[:error]
  end

  test 'should create data file with http_url' do
    mock_http
    data_file, blob = valid_data_file_with_http_url

    assert_difference('DataFile.count') do
      assert_difference('ContentBlob.count') do
        post :create, params: { data_file: data_file, content_blobs: [blob], policy_attributes: valid_sharing }
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner).person, assigns(:data_file).contributor
    assert !assigns(:data_file).content_blob.url.blank?
    assert assigns(:data_file).content_blob.data_io_object.nil?
    assert !assigns(:data_file).content_blob.file_exists?
    assert_equal 'text/plain', assigns(:data_file).content_blob.content_type
    assert_equal 'txt_test.txt', assigns(:data_file).content_blob.original_filename
  end

  test 'should create data file with https_url' do
    mock_https
    data_file, blob = valid_data_file_with_https_url

    assert_difference('DataFile.count') do
      assert_difference('ContentBlob.count') do
        post :create, params: { data_file: data_file, content_blobs: [blob], policy_attributes: valid_sharing }
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner).person, assigns(:data_file).contributor
    assert !assigns(:data_file).content_blob.url.blank?
    assert assigns(:data_file).content_blob.data_io_object.nil?
    assert !assigns(:data_file).content_blob.file_exists?
    assert_equal 'txt_test.txt', assigns(:data_file).content_blob.original_filename
    assert_equal 'text/plain', assigns(:data_file).content_blob.content_type
  end

  test 'should not create data file with file url' do
    file_path = File.expand_path(__FILE__) # use the current file
    file_url = 'file://' + file_path
    uri = URI.parse(file_url)

    assert_no_difference('ActivityLog.count') do
      assert_no_difference('DataFile.count') do
        assert_no_difference('ContentBlob.count') do
          post :create, params: { data_file: { title: 'Test' }, content_blobs: [{ data_url: uri.to_s }], policy_attributes: valid_sharing }
        end
      end
    end

    assert_not_nil flash[:error]
  end

  test 'should create data file and store with url' do
    mock_http
    data, blob = valid_data_file_with_http_url
    blob[:make_local_copy] = '1'

    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, params: { data_file: data, content_blobs: [blob], policy_attributes: valid_sharing }
        end
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner).person, assigns(:data_file).contributor
    assert !assigns(:data_file).content_blob.url.blank?
    assert_equal 'txt_test.txt', assigns(:data_file).content_blob.original_filename
    assert_equal 'text/plain', assigns(:data_file).content_blob.content_type
  end

  test 'should create data file and store with url even with http protocol missing' do
    mock_http
    data, blob = valid_data_file_with_http_url
    blob[:data_url] = 'mockedlocation.com/txt_test.txt'
    blob[:make_local_copy] = '1'

    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, params: { data_file: data, content_blobs: [blob], policy_attributes: valid_sharing }
        end
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner).person, assigns(:data_file).contributor
    assert !assigns(:data_file).content_blob.url.blank?
    assert_equal 'txt_test.txt', assigns(:data_file).content_blob.original_filename
    assert_equal 'text/plain', assigns(:data_file).content_blob.content_type
  end

  test 'should correctly handle 404 url' do
    mock_http
    df = { title: 'Test' }
    blob = { data_url: 'http://mocked404.com' }
    assert_no_difference('ActivityLog.count') do
      assert_no_difference('DataFile.count') do
        assert_no_difference('ContentBlob.count') do
          post :create, params: { data_file: df, content_blobs: [blob], policy_attributes: valid_sharing }
        end
      end
    end

    assert_not_nil flash.now[:error]
  end

  test 'should create data file' do
    login_as(:datafile_owner) # can edit assay
    assay = assays(:assay_can_edit_by_datafile_owner)
    data_file, blob = valid_data_file
    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_difference('DataFile::Version.count') do
          assert_difference('ContentBlob.count') do
            post :create, params: { data_file: data_file.merge(assay_assets_attributes: [{ assay_id: assay.id }]), content_blobs: [blob], policy_attributes: valid_sharing }
          end
        end
      end
    end
    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner).person, assigns(:data_file).contributor

    assert !assigns(:data_file).content_blob.data_io_object.read.nil?
    assert assigns(:data_file).content_blob.url.blank?
    assert_equal 1, assigns(:data_file).version
    assert_not_nil assigns(:data_file).latest_version
    refute assigns(:data_file).simulation_data?
    assay.reload
    assert_includes assay.data_files, assigns(:data_file)
  end

  test 'should create data file as simulation data' do
    login_as(:datafile_owner) # can edit assay
    data_file, blob = valid_data_file
    data_file[:simulation_data] = '1'
    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_difference('DataFile::Version.count') do
          assert_difference('ContentBlob.count') do
            post :create, params: { data_file: data_file, content_blobs: [blob], policy_attributes: valid_sharing }
          end
        end
      end
    end
    assert_redirected_to data_file_path(assigns(:data_file))
    assert assigns(:data_file).simulation_data?
  end

  test 'upload_for_tool inacessible with normal login' do
    post :upload_for_tool, params: { data_file: { title: 'Test', data: fixture_file_upload('files/file_picture.png'), project_id: projects(:sysmo_project).id }, recipient_id: people(:quentin_person).id }
    assert_redirected_to root_url
  end

  test 'upload_from_email inacessible with normal login' do
    post :upload_from_email, params: { data_file: { title: 'Test', data: fixture_file_upload('files/file_picture.png'), project_id: projects(:sysmo_project).id }, recipient_ids: [people(:quentin_person).id], cc_ids: [] }
    assert_redirected_to root_url
  end

  test 'should create data file for upload tool' do
    assert_difference('DataFile.count') do
      assert_difference('ContentBlob.count') do
        session[:xml_login] = true
        post :upload_for_tool, params: { data_file: { title: 'Test', project_id: projects(:sysmo_project).id }, content_blobs: [{ data: picture_file }], recipient_id: people(:quentin_person).id }
      end
    end

    assert_response :success
    df = assigns(:data_file)
    df.reload
    assert_equal users(:datafile_owner).person, df.contributor

    assert !df.content_blob.data_io_object.read.nil?
    assert df.content_blob.url.blank?
    assert df.policy
    assert df.policy.permissions
    assert_equal df.policy.permissions.first.contributor, people(:quentin_person)
    assert df.creators
    assert_equal df.creators.first, users(:datafile_owner).person
  end

  test 'should create data file from email tool' do
    old_admin_impersonation = Seek::Config.admin_impersonation_enabled
    Seek::Config.admin_impersonation_enabled = true
    login_as Factory(:admin).user
    assert_difference('DataFile.count') do
      assert_difference('ContentBlob.count') do
        session[:xml_login] = true
        post :upload_from_email, params: { data_file: { title: 'Test', project_ids: [projects(:sysmo_project).id] }, content_blobs: [{ data: picture_file }], recipient_ids: [people(:quentin_person).id], sender_id: users(:datafile_owner).person_id }
      end
    end

    assert_response :success
    df = assigns(:data_file)
    df.reload
    assert_equal users(:datafile_owner).person, df.contributor

    assert !df.content_blob.data_io_object.read.nil?
    assert df.content_blob.url.blank?
    assert df.policy
    assert df.policy.permissions
    assert_equal df.policy.permissions.first.contributor, people(:quentin_person)
    assert df.creators
    assert_equal df.creators.first, users(:datafile_owner).person
    Seek::Config.admin_impersonation_enabled = old_admin_impersonation
  end

  test 'missing sharing should default' do
    with_config_value 'default_all_visitors_access_type', Policy::NO_ACCESS do
      data_file, blob = valid_data_file
      assert_difference('ActivityLog.count') do
        assert_difference('DataFile.count') do
          assert_difference('ContentBlob.count') do
            post :create, params: { data_file: data_file, content_blobs: [blob] }
          end
        end
      end
      assert_redirected_to data_file_path(assigns(:data_file))
      assert_equal users(:datafile_owner).person, assigns(:data_file).contributor
      assert assigns(:data_file)
      df = assigns(:data_file)
      assert_equal Policy::NO_ACCESS, df.policy.access_type
      assert df.policy.permissions.empty?

      # check it doesn't create an error when retreiving the index
      get :index
      assert_response :success
    end
  end

  test 'should show data file' do
    d = Factory :rightfield_datafile, policy: Factory(:public_policy)
    assert_difference('ActivityLog.count') do
      get :show, params: { id: d }
    end
    assert_response :success

    assert_select 'div.box_about_actor' do
      assert_select 'p > b', text: /Filename:/
      assert_select 'p', text: /rightfield\.xls/
      assert_select 'p > b', text: /Format:/
      assert_select 'p', text: /Spreadsheet/
      assert_select 'p > b', text: /Size:/
      assert_select 'p', text: /9 KB/
    end
  end

  test 'should add link to a webpage' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/html_file.html", 'http://webpage.com', 'Content-Type' => 'text/html'

    data_file = { title: 'Test HTTP', project_ids: [projects(:sysmo_project).id] }
    blob = { data_url: 'http://webpage.com' }

    assert_difference('DataFile.count') do
      assert_difference('ContentBlob.count') do
        post :create, params: { data_file: data_file, content_blobs: [blob], policy_attributes: valid_sharing }
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner).person, assigns(:data_file).contributor
    refute assigns(:data_file).content_blob.url.blank?
    assert assigns(:data_file).content_blob.data_io_object.nil?
    refute assigns(:data_file).content_blob.file_exists?
    assert_equal '', assigns(:data_file).content_blob.original_filename
    assert assigns(:data_file).content_blob.is_webpage?
    assert_equal 'http://webpage.com', assigns(:data_file).content_blob.url
    assert_equal 'text/html', assigns(:data_file).content_blob.content_type
  end

  test 'should add link to a webpage with http protocol missing' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/html_file.html", 'http://webpage.com', 'Content-Type' => 'text/html'

    data_file = { title: 'Test HTTP', project_ids: [projects(:sysmo_project).id] }
    blob = { data_url: 'webpage.com' }

    assert_difference('DataFile.count') do
      assert_difference('ContentBlob.count') do
        post :create, params: { data_file: data_file, content_blobs: [blob], policy_attributes: valid_sharing }
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner).person, assigns(:data_file).contributor
    refute assigns(:data_file).content_blob.url.blank?
    assert assigns(:data_file).content_blob.data_io_object.nil?
    refute assigns(:data_file).content_blob.file_exists?
    assert_equal '', assigns(:data_file).content_blob.original_filename
    assert assigns(:data_file).content_blob.is_webpage?
    assert_equal 'http://webpage.com', assigns(:data_file).content_blob.url
    assert_equal 'text/html', assigns(:data_file).content_blob.content_type
  end

  test 'should add link to a webpage from windows browser' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/html_file.html", 'http://webpage.com', 'Content-Type' => 'text/html'
    data_file = { title: 'Test HTTP', project_ids: [projects(:sysmo_project).id] }
    blob = { data_url: 'http://webpage.com' }

    assert_difference('DataFile.count') do
      assert_difference('ContentBlob.count') do
        @request.env['HTTP_USER_AGENT'] = 'Windows'
        post :create, params: { data_file: data_file, content_blobs: [blob], policy_attributes: valid_sharing }
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner).person, assigns(:data_file).contributor
    assert !assigns(:data_file).content_blob.url.blank?
    assert assigns(:data_file).content_blob.data_io_object.nil?
    assert !assigns(:data_file).content_blob.file_exists?
    assert_equal '', assigns(:data_file).content_blob.original_filename
    assert assigns(:data_file).content_blob.is_webpage?
    assert_equal 'http://webpage.com', assigns(:data_file).content_blob.url
    assert_equal 'text/html', assigns(:data_file).content_blob.content_type
  end

  test 'should show webpage as a link' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/html_file.html", 'http://webpage.com', 'Content-Type' => 'text/html'

    df = Factory :data_file, content_blob: Factory(:content_blob, url: 'http://webpage.com')

    assert df.content_blob.is_webpage?
    login_as(df.contributor.user)
    get :show, params: { id: df }
    assert_response :success

    assert_select '#buttons a.btn[href=?]', 'http://webpage.com', text: 'External Link'

    assert_select 'div.box_about_actor' do
      assert_select 'p > b', text: /Link:/
      assert_select 'a[href=?][target=_blank]', 'http://webpage.com', text: 'http://webpage.com'
      assert_select 'p > b', text: /Format:/, count: 0
      assert_select 'p > b', text: /Size:/, count: 0
    end
  end

  test 'should show URL with unrecognized scheme as a link' do
    df = Factory :data_file, content_blob: Factory(:content_blob, url: 'spotify:track:3vX71b5ey9twzyCqJwBEvY')

    assert df.content_blob.show_as_external_link?
    login_as(df.contributor.user)
    get :show, params: { id: df }
    assert_response :success

    assert_select '#buttons a.btn[href=?]', 'spotify:track:3vX71b5ey9twzyCqJwBEvY', text: 'External Link'

    assert_select 'div.box_about_actor' do
      assert_select 'p > b', text: /Link:/
      assert_select 'a[href=?][target=_blank]', 'spotify:track:3vX71b5ey9twzyCqJwBEvY', text: 'spotify:track:3vX71b5ey9twzyCqJwBEvY'
      assert_select 'p > b', text: /Format:/, count: 0
      assert_select 'p > b', text: /Size:/, count: 0
    end
  end

  test 'should not show website link for viewable but inaccessible data but should show request button' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/html_file.html", 'http://webpage.com', 'Content-Type' => 'text/html'
    df = Factory :data_file, content_blob: Factory(:content_blob, url: 'http://webpage.com'), policy: Factory(:all_sysmo_viewable_policy)
    user = Factory :user
    assert df.can_view?(user)
    assert !df.can_download?(user)
    login_as(user)
    get :show, params: { id: df }
    assert_response :success

    assert_select 'div.box_about_actor' do
      assert_select 'p > b', text: /Link/, count: 0
      assert_select 'a[href=?][target=_blank]', 'http://webpage.com', text: 'http://webpage.com', count: 0
    end

    assert_select '#buttons' do
      assert_select 'a', text: /Request Contact/, count: 1
    end
  end

  test 'svg handles quotes in title' do
    d = Factory :rightfield_datafile, title: '"Title with quote', policy: Factory(:public_policy)

    assert_difference('ActivityLog.count') do
      get :show, params: { id: d }
    end

    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: data_files(:picture) }
    assert_response :success
    assert_select 'h1', text: /Editing #{I18n.t('data_file')}/
  end

  test 'publications included in form for datafile' do
    get :edit, params: { id: data_files(:picture) }
    assert_response :success
    assert_select 'div#add_publications_form', true

    register_content_blob
    assert_response :success
    assert_select 'div#add_publications_form', true
  end

  test 'dont show download button or count for website/external_link data file' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/html_file.html", 'http://webpage.com', 'Content-Type' => 'text/html'
    df = Factory :data_file, content_blob: Factory(:content_blob, url: 'http://webpage.com', external_link: true)
    assert df.content_blob.is_webpage?
    login_as(df.contributor.user)
    assert df.can_download?(df.contributor.user)
    get :show, params: { id: df }
    assert_response :success
    assert_select '#buttons' do
      assert_select 'a[href=?]', download_data_file_path(df, version: df.version), count: 0
      assert_select 'a', text: /Download/, count: 0
    end

    assert_select '#usage_count' do
      assert_select 'strong', text: /Downloads/, count: 0
    end
  end

  test 'show download button for non website data file' do
    df = Factory :data_file
    login_as(df.contributor.user)
    get :show, params: { id: df }
    assert_response :success
    assert_select '#buttons' do
      assert_select 'a[href=?]', download_data_file_path(df, version: df.version), count: 1
      assert_select 'a', text: /Download/, count: 1
    end

    assert_select '#usage_count' do
      assert_select 'strong', text: /Downloads/, count: 1
    end
  end

  test 'show explore button' do
    df = Factory(:small_test_spreadsheet_datafile)
    login_as(df.contributor.user)
    get :show, params: { id: df }
    assert_response :success
    assert_select '#buttons' do
      assert_select 'a[href=?]', explore_data_file_path(df, version: df.version), count: 1
      assert_select 'a.disabled', text: 'Explore', count: 0
    end
  end
  
  test 'show explore button for csv file' do
    df = Factory(:csv_spreadsheet_datafile)
    login_as(df.contributor.user)
    get :show, params: { id: df }
    assert_response :success
    assert_select '#buttons' do
      assert_select 'a[href=?]', explore_data_file_path(df, version: df.version), count: 1
      assert_select 'a.disabled', text: 'Explore', count: 0
    end
  end

  
  test 'not show explore button if spreadsheet not supported' do
    df = Factory(:non_spreadsheet_datafile)
    login_as(df.contributor.user)
    with_config_value(:max_extractable_spreadsheet_size, 0) do
      get :show, params: { id: df }
    end
    assert_response :success
    assert_select '#buttons' do
      assert_select 'a[href=?]', explore_data_file_path(df, version: df.version), count: 0
      assert_select 'a', text: 'Explore', count: 0
    end
  end

  test 'show disabled explore button if spreadsheet too big' do
    df = Factory(:small_test_spreadsheet_datafile)
    login_as(df.contributor.user)
    with_config_value(:max_extractable_spreadsheet_size, 0) do
      get :show, params: { id: df }
    end
    assert_response :success
    assert_select '#buttons' do
      assert_select 'a[href=?]', explore_data_file_path(df, version: df.version), count: 0
      assert_select 'a.disabled', text: 'Explore', count: 1
    end
  end

  test 'should download datafile from standard route' do
    df = Factory :rightfield_datafile, policy: Factory(:public_policy)
    login_as(df.contributor.user)
    assert_difference('ActivityLog.count') do
      get :download, params: { id: df.id }
    end
    assert_response :success
    al = ActivityLog.last
    assert_equal 'download', al.action
    assert_equal df, al.activity_loggable
    assert_equal 'attachment; filename="rightfield.xls"', @response.header['Content-Disposition']
    assert_equal 'application/vnd.ms-excel', @response.header['Content-Type']
    assert_equal '9216', @response.header['Content-Length']
  end

  test 'should download' do
    assert_difference('ActivityLog.count') do
      get :download, params: { id: Factory(:small_test_spreadsheet_datafile, policy: Factory(:public_policy), contributor: User.current_user.person).id }
    end
    assert_response :success
    assert_equal 'attachment; filename="small-test-spreadsheet.xls"', @response.header['Content-Disposition']
    assert_equal 'application/vnd.ms-excel', @response.header['Content-Type']
    assert_equal '7168', @response.header['Content-Length']
  end

  test 'should download from url' do
    mock_http
    data_file = data_files(:url_based_data_file)
    assert_difference('ActivityLog.count') do
      get :download, params: { id: data_files(:url_based_data_file) }
    end
    assert_not_empty @response.body
    assert_response :success
  end

  test 'should gracefully handle when downloading a unknown host url' do
    stub_request(:any, 'http://sdkfhsdfkhskfj.com/pic.png').to_raise(SocketError)
    df = data_files(:url_no_host_data_file)
    get :download, params: { id: df }
    assert_redirected_to data_file_path(df, version: df.version)
    assert_not_nil flash[:error]
  end

  test 'should gracefully handle when downloading a url resulting in 404' do
    mock_http
    df = data_files(:url_not_found_data_file)
    get :download, params: { id: df }
    assert_redirected_to data_file_path(df, version: df.version)
    assert_not_nil flash[:error]
  end

  test 'should redirect on download for 401 url' do
    mock_http
    df = { title: '401', project_ids: [projects(:sysmo_project).id] }
    blob = { data_url: 'http://mocked401.com/file.txt' }
    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, params: { data_file: df, content_blobs: [blob], policy_attributes: valid_sharing }
        end
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner).person, assigns(:data_file).contributor
    refute assigns(:data_file).content_blob.url.blank?
    assert assigns(:data_file).content_blob.data_io_object.nil?
    refute assigns(:data_file).content_blob.file_exists?
    assert_equal 'file.txt', assigns(:data_file).content_blob.original_filename
    assert_equal 'text/plain', assigns(:data_file).content_blob.content_type

    get :download, params: { id: assigns(:data_file) }

    assert_redirected_to assigns(:data_file).content_blob.url
  end

  test 'should redirect and show error on download for 403 url' do
    mock_http
    df = { title: '401', project_ids: [projects(:sysmo_project).id] }
    blob = { data_url: 'http://mocked403.com/file.txt' }
    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, params: { data_file: df, content_blobs: [blob], policy_attributes: valid_sharing }
        end
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner).person, assigns(:data_file).contributor
    refute assigns(:data_file).content_blob.url.blank?
    assert assigns(:data_file).content_blob.data_io_object.nil?
    refute assigns(:data_file).content_blob.file_exists?
    assert_equal 'file.txt', assigns(:data_file).content_blob.original_filename
    assert_equal 'text/plain', assigns(:data_file).content_blob.content_type

    get :download, params: { id: assigns(:data_file) }

    assert_redirected_to assigns(:data_file).content_blob.url
  end

  test 'should create and redirect on download for 302 url' do
    mock_http
    df = { title: '302', project_ids: [projects(:sysmo_project).id] }
    blob = { data_url: 'http://mocked302.com', make_local_copy: '0' }
    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, params: { data_file: df, content_blobs: [blob], policy_attributes: valid_sharing }
        end
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner).person, assigns(:data_file).contributor
    refute assigns(:data_file).content_blob.url.blank?
    assert assigns(:data_file).content_blob.data_io_object.nil?
    refute assigns(:data_file).content_blob.file_exists?
    assert_equal '', assigns(:data_file).content_blob.original_filename
    assert_equal 'text/html', assigns(:data_file).content_blob.content_type

    get :download, params: { id: assigns(:data_file) }
    assert_response :success
  end

  test 'should create and transparently redirect on download for 301 url' do
    mock_http
    df = { title: '301', project_ids: [projects(:sysmo_project).id] }
    blob = { data_url: 'http://mocked301.com', make_local_copy: '0' }
    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, params: { data_file: df, content_blobs: [blob], policy_attributes: valid_sharing }
        end
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal users(:datafile_owner).person, assigns(:data_file).contributor
    refute assigns(:data_file).content_blob.url.blank?
    assert assigns(:data_file).content_blob.data_io_object.nil?
    refute assigns(:data_file).content_blob.file_exists?
    assert_equal '', assigns(:data_file).content_blob.original_filename
    assert_equal 'text/html', assigns(:data_file).content_blob.content_type

    get :download, params: { id: assigns(:data_file) }
    assert_response :success
  end

  test 'report error when file unavailable for download' do
    df = Factory :data_file, policy: Factory(:public_policy)
    df.content_blob.dump_data_to_file
    assert df.content_blob.file_exists?
    FileUtils.rm df.content_blob.filepath
    assert !df.content_blob.file_exists?

    get :download, params: { id: df }

    assert_redirected_to df
    assert flash[:error].match(/Unable to find a copy of the file for download/)
  end

  test 'should handle inline download when specify the inline disposition' do
    data = File.new("#{Rails.root}/test/fixtures/files/file_picture.png", 'rb').read
    df = Factory :data_file,
                 content_blob: Factory(:content_blob, data: data, content_type: 'images/png'),
                 policy: Factory(:downloadable_public_policy)

    get :download, params: { id: df, disposition: 'inline' }
    assert_response :success
    assert @response.header['Content-Disposition'].include?('inline')
  end

  test 'should handle normal attachment download' do
    data = File.new("#{Rails.root}/test/fixtures/files/file_picture.png", 'rb').read
    df = Factory :data_file,
                 content_blob: Factory(:content_blob, data: data, content_type: 'images/png'),
                 policy: Factory(:downloadable_public_policy)

    get :download, params: { id: df }
    assert_response :success
    assert @response.header['Content-Disposition'].include?('attachment')
  end

  test "shouldn't download" do
    login_as(:aaron)
    get :download, params: { id: data_files(:viewable_data_file) }
    assert_redirected_to data_file_path(data_files(:viewable_data_file))
    assert flash[:error]
  end

  test 'should update data file' do
    df = Factory(:data_file, contributor:User.current_user.person)
    assert_difference('ActivityLog.count') do
      put :update, params: { id: df.id, data_file: { title: 'diff title' } }
    end

    assert_equal 'Data file metadata was successfully updated.', flash[:notice]
    assert_redirected_to data_file_path(df)
    assert_equal 'diff title',assigns(:data_file).title
  end
  #
  # test 'should update data file with workflow link' do
  #   df = Factory(:data_file, contributor:User.current_user.person)
  #   workflow = Factory(:workflow, contributor: User.current_user.person)
  #   assert_empty df.workflows
  #   assert_difference('ActivityLog.count') do
  #     put :update, params: { id: df.id, data_file: { workflow_ids: [workflow.id] } }
  #   end
  #
  #   assert_equal 'Data file metadata was successfully updated.', flash[:notice]
  #   assert_equal [workflow], assigns(:data_file).workflows
  #   assert_redirected_to data_file_path(df)
  # end

  test 'should update data_file with workflow link' do

    person = Factory(:person)
    workflow = Factory(:workflow, contributor: person)
    data_file = Factory(:data_file, contributor:person)
    relationship = Factory(:test_data_workflow_data_file_relationship)
    login_as(person)
    assert_empty data_file.workflows

    assert_difference('ActivityLog.count') do
      assert_difference('WorkflowDataFile.count') do
        put :update, params: { id: data_file.id, data_file: {
          workflow_data_files_attributes: ['',{workflow_id: workflow.id, workflow_data_file_relationship_id:relationship.id}]
        } }
      end
    end

    assert_redirected_to data_file_path(data_file = assigns(:data_file))
    assert_equal [workflow], data_file.workflows
    assert_equal 1,data_file.workflow_data_files.count
    assert_equal [relationship.id], data_file.workflow_data_files.pluck(:workflow_data_file_relationship_id)

    # doesn't duplicate
    assert_difference('ActivityLog.count') do
      assert_no_difference('WorkflowDataFile.count') do
        put :update, params: { id: data_file.id, data_file: {
          workflow_data_files_attributes: ['',{workflow_id: workflow.id, workflow_data_file_relationship_id:relationship.id}]
        } }
      end
    end
    assert_redirected_to data_file_path(data_file = assigns(:data_file))
    assert_equal [workflow], data_file.workflows
    assert_equal 1,data_file.workflow_data_files.count
    assert_equal [relationship.id], data_file.workflow_data_files.pluck(:workflow_data_file_relationship_id)

    #removes
    assert_difference('ActivityLog.count') do
      assert_difference('WorkflowDataFile.count', -1) do
        put :update, params: { id: data_file.id, data_file: {
          workflow_data_files_attributes: ['']
        } }
      end
    end
    assert_redirected_to data_file_path(data_file = assigns(:data_file))
    assert_equal [], data_file.workflows
    assert_equal 0,data_file.workflow_data_files.count
    assert_equal [], data_file.workflow_data_files.pluck(:workflow_data_file_relationship_id)
  end

  test 'should destroy DataFile' do
    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count', -1) do
        assert_no_difference('ContentBlob.count') do
          delete :destroy, params: { id: data_files(:editable_data_file).id }
        end
      end
    end

    assert_redirected_to data_files_path
  end

  test 'should be possible to delete one version of data file' do
    with_config_value :delete_asset_version_enabled, true do
      # upload a data file
      df = Factory :data_file, contributor: User.current_user.person
      # upload new version 1 of the data file
      post :create_version, params: { id: df, data_file: { title: nil }, content_blobs: [{ data: picture_file }], revision_comments: 'This is a new revision 1' }
      # upload new version 2 of the data file
      post :create_version, params: { id: df, data_file: { title: nil }, content_blobs: [{ data: picture_file }], revision_comments: 'This is a new revision 2' }

      df.reload
      assert_equal 3, df.versions.length

      # the latest version is 3
      assert_equal 3, df.version

      assert_difference('df.versions.length', -1) do
        put :destroy_version, params: { id: df, version: 3 }
        df.reload
      end
      # the latest version becomes 2
      assert_equal 2, df.version
      assert_redirected_to data_file_path(df)
    end
  end

  test 'adding_new_conditions_to_different_versions' do
    d = Factory(:data_file, contributor: User.current_user.person)
    assert d.can_edit?
    sf = StudiedFactor.create(unit_id: units(:gram).id, measured_item: measured_items(:weight),
                              start_value: 1, end_value: 2, data_file_id: d.id, data_file_version: d.version)

    assert_difference('DataFile::Version.count', 1) do
      assert_difference('StudiedFactor.count', 1) do
        post :create_version, params: { id: d, data_file: { title: nil }, content_blobs: [{ data: picture_file }], revision_comments: 'This is a new revision' } # v2
      end
    end

    d.find_version(2).studied_factors.each(&:destroy)
    assert_equal sf, d.find_version(1).studied_factors.first
    assert_equal 0, d.find_version(2).studied_factors.count

    sf2 = StudiedFactor.create(unit_id: units(:gram).id, measured_item: measured_items(:weight),
                               start_value: 2, end_value: 3, data_file_id: d.id, data_file_version: 2)

    assert_not_equal 0, d.find_version(2).studied_factors.count
    assert_equal sf2, d.find_version(2).studied_factors.first
    assert_not_equal sf2, d.find_version(1).studied_factors.first
    assert_equal sf, d.find_version(1).studied_factors.first
  end

  def test_should_add_nofollow_to_links_in_show_page
    assert_difference('ActivityLog.count') do
      get :show, params: { id: data_files(:data_file_with_links_in_description) }
    end

    assert_select 'div#description' do
      assert_select 'a[rel="nofollow"]'
    end
  end

  def test_update_should_not_overwrite_contributor
    login_as(:datafile_owner) # this user is a member of sysmo, and can edit this data file
    df = data_files(:data_file_with_no_contributor)
    assert_difference('ActivityLog.count') do
      put :update, params: { id: df, data_file: { title: 'blah blah blah blah' } }
    end

    updated_df = assigns(:data_file)
    assert_redirected_to data_file_path(updated_df)
    assert_equal 'blah blah blah blah', updated_df.title, 'Title should have been updated'
    assert_nil updated_df.contributor, 'contributor should still be nil'
  end

  def test_show_item_attributed_to_jerm_file
    login_as(:datafile_owner) # this user is a member of sysmo, and can edit this data file
    df = data_files(:editable_data_file)
    jerm_file = data_files(:data_file_with_no_contributor)
    r = Relationship.new(subject: df, predicate: Relationship::ATTRIBUTED_TO, other_object: jerm_file)
    r.save!
    df = DataFile.find(df.id)
    assert df.attributions.collect(&:other_object).include?(jerm_file), 'The datafile should have had the jerm file added as an attribution'
    assert_difference('ActivityLog.count') do
      get :show, params: { id: df }
    end

    assert_response :success
    assert :success
  end

  test 'filtering by assay' do
    assay = assays(:metabolomics_assay)
    get :index, params: { filter: { assay: assay.id } }
    assert_response :success
  end

  test 'filtering by study' do
    study = studies(:metabolomics_study)
    get :index, params: { filter: { study: study.id } }
    assert_response :success
  end

  test 'filtering by investigation' do
    inv = investigations(:metabolomics_investigation)
    get :index, params: { filter: { investigation: inv.id } }
    assert_response :success
  end

  test 'filtering by project' do
    project = projects(:sysmo_project)
    get :index, params: { filter: { project: project.id } }
    assert_response :success
  end

  test 'filtering by person' do
    person = people(:person_for_datafile_owner)
    get :index, params: { filter: { contributor: person.id }, page: 'all' }
    assert_response :success
    non_owned_df = data_files(:sysmo_data_file)

    assert_select 'div.list_items_container' do
      person.contributed_data_files.each do |df|
        assert_select 'a', text: df.title, count: 1
      end
      assert_select 'a', text: non_owned_df.title, count: 0
    end
  end

  test 'should not be able to update sharing without manage rights' do
    refute_nil user = User.current_user
    df = Factory(:data_file,policy: Factory(:editing_public_policy))

    assert df.can_edit?(user), 'data file should be editable but not manageable for this test'
    assert !df.can_manage?(user), 'data file should be editable but not manageable for this test'
    assert_equal Policy::EDITING, df.policy.access_type, 'data file should have an initial policy with access type for editing'
    assert_difference('ActivityLog.count') do
      put :update, params: { id: df, data_file: { title: 'new title' }, policy_attributes: { access_type: Policy::NO_ACCESS } }
    end

    assert_redirected_to data_file_path(df)
    df.reload

    assert_equal 'new title', df.title
    assert_equal Policy::EDITING, df.policy.access_type, 'policy should not have been updated'
  end

  test 'should not be able to update sharing permission without manage rights' do

    refute_nil user = User.current_user
    df = Factory(:data_file,policy: Factory(:editing_public_policy))
    assert df.can_edit?(user), 'data file should be editable but not manageable for this test'
    refute df.can_manage?(user), 'data file should be editable but not manageable for this test'
    assert_equal Policy::EDITING, df.policy.access_type, 'data file should have an initial policy with access type for editing'
    assert_difference('ActivityLog.count') do
      put :update, params: { id: df, data_file: { title: 'new title' }, policy_attributes: { access_type: Policy::NO_ACCESS,
                                                                                             permissions_attributes: { contributor_type: 'Person',
                                                                                                                       contributor_id: user.person.id,
                                                                                                                       access_type: Policy::MANAGING } } }
    end

    assert_redirected_to data_file_path(df)
    df.reload
    assert_equal 'new title', df.title
    assert !df.can_manage?(user)
  end

  test 'fail gracefullly when trying to access a missing data file' do
    get :show, params: { id: 99_999 }
    assert_response :not_found
  end

  test 'owner should be able to update sharing' do
    refute_nil user = User.current_user

    df = Factory(:data_file, policy: Factory(:editing_public_policy),contributor: user.person)


    assert df.can_edit?(user), 'data file should be editable and manageable for this test'
    assert df.can_manage?(user), 'data file should be editable and manageable for this test'
    assert_equal Policy::EDITING, df.policy.access_type, 'data file should have an initial policy with access type for editing'
    assert_difference('ActivityLog.count') do
      put :update, params: { id: df, data_file: { title: 'new title' }, policy_attributes: { access_type: Policy::NO_ACCESS } }
    end

    assert_redirected_to data_file_path(df)
    df.reload

    assert_equal 'new title', df.title
    assert_equal Policy::NO_ACCESS, df.policy.access_type, 'policy should have been updated'
  end

  test 'update with ajax only applied when viewable' do
    p = Factory :person
    p2 = Factory :person
    viewable_df = Factory :data_file, contributor: p2, policy: Factory(:publicly_viewable_policy)
    dummy_df = Factory :data_file

    login_as p.user

    assert viewable_df.can_view?(p.user)
    assert !viewable_df.can_edit?(p.user)

    golf = Factory :tag, annotatable: dummy_df, source: p2, value: 'golf'

    post :update_annotations_ajax, xhr: true, params: { id: viewable_df, tag_list: golf.value.text }

    viewable_df.reload

    assert_equal ['golf'], viewable_df.annotations.collect { |a| a.value.text }

    private_df = Factory :data_file, contributor: p2, policy: Factory(:private_policy)

    assert !private_df.can_view?(p.user)
    assert !private_df.can_edit?(p.user)

    post :update_annotations_ajax, xhr: true, params: { id: private_df, tag_list: golf.value.text }

    private_df.reload
    assert private_df.annotations.empty?
  end

  test 'update tags with ajax' do
    p = Factory :person

    login_as p.user

    p2 = Factory :person
    df = Factory :data_file, contributor: p

    assert df.annotations.empty?, 'this data file should have no tags for the test'

    golf = Factory :tag, annotatable: df, source: p2.user, value: 'golf'
    Factory :tag, annotatable: df, source: p2.user, value: 'sparrow'

    df.reload

    assert_equal %w[golf sparrow], df.annotations.collect { |a| a.value.text }.sort
    assert_equal [], df.annotations.select { |a| a.source == p.user }.collect { |a| a.value.text }.sort
    assert_equal %w[golf sparrow], df.annotations.select { |a| a.source == p2.user }.collect { |a| a.value.text }.sort

    post :update_annotations_ajax, xhr: true, params: { id: df, tag_list: "soup, #{golf.value.text}" }

    df.reload

    assert_equal %w[golf soup sparrow], df.annotations.collect { |a| a.value.text }.uniq.sort
    assert_equal %w[golf soup], df.annotations.select { |a| a.source == p.user }.collect { |a| a.value.text }.sort
    assert_equal %w[golf sparrow], df.annotations.select { |a| a.source == p2.user }.collect { |a| a.value.text }.sort
  end

  test 'correct response to unknown action' do
    df = data_files(:picture)
    assert_raises ActionController::UrlGenerationError do
      get :sdkfjshdfkhsdf, params: { id: df }
    end
  end

  test "should create sharing permissions 'with your project and with all SysMO members'" do
    mock_http
    data_file, blob = valid_data_file_with_http_url
    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, params: { data_file: data_file, content_blobs: [blob], policy_attributes: projects_policy(Policy::VISIBLE, data_file[:project_ids], Policy::ACCESSIBLE) }
        end
      end
    end

    df = assigns(:data_file)
    assert_redirected_to data_file_path(df)
    assert_equal Policy::VISIBLE, df.policy.access_type
    assert_equal df.policy.permissions.count, 1

    permission = df.policy.permissions.first
    assert_equal permission.contributor_type, 'Project'
    assert_equal permission.contributor_id, df.project_ids.first
    assert_equal permission.policy_id, df.policy_id
    assert_equal permission.access_type, Policy::ACCESSIBLE
  end

  test "should update sharing permissions 'with your project and with all SysMO members'" do
    # login_as(:datafile_owner)
    # df = data_files(:editable_data_file)

    refute_nil user = User.current_user
    df = Factory(:data_file, contributor: user.person, policy: Factory(:editing_public_policy, permissions:[Factory(:permission)]))

    assert df.can_manage?
    assert_equal Policy::EDITING, df.policy.access_type
    assert_equal df.policy.permissions.length, 1

    permission = df.policy.permissions.first
    assert_equal permission.contributor_type, 'Person'
    assert_equal permission.policy_id, df.policy_id
    assert_equal permission.access_type, Policy::NO_ACCESS
    assert_difference('ActivityLog.count') do
      put :update, params: { id: df, data_file: { title: df.title }, policy_attributes: projects_policy(Policy::ACCESSIBLE, df.projects, Policy::EDITING) }
    end
    df.reload

    assert_redirected_to data_file_path(df)
    assert_equal Policy::ACCESSIBLE, df.policy.access_type
    assert_equal 1, df.policy.permissions.length

    update_permission = df.policy.permissions.first
    assert_equal update_permission.contributor_type, 'Project'
    assert_equal update_permission.contributor_id, df.project_ids.first
    assert_equal update_permission.policy_id, df.policy_id
    assert_equal update_permission.access_type, Policy::EDITING
  end

  test 'do not remove permissions when updating permission' do
    df = Factory :data_file, policy: Factory(:private_policy)
    Factory :permission, policy: df.policy

    login_as(df.contributor)

    put :update, params: { id: df, data_file: { title: df.title }, policy_attributes: projects_policy(Policy::NO_ACCESS, df.projects, Policy::ACCESSIBLE) }

    assert_redirected_to df

    df.reload
    permissions = df.policy.permissions
    assert_equal 1, permissions.size
    permission = permissions.first
    assert_equal 'Project', permission.contributor_type
    assert_equal df.projects.first.id, permission.contributor_id
    assert_equal Policy::ACCESSIBLE, permission.access_type
  end

  test 'explore logged as inline_view' do
    data = Factory :small_test_spreadsheet_datafile, policy: Factory(:public_policy)
    assert_difference('ActivityLog.count') do
      get :explore, params: { id: data }
    end
    assert_response :success
    al = ActivityLog.last
    assert_equal data, al.activity_loggable
    assert_equal User.current_user, al.culprit
    assert_equal 'inline_view', al.action
    assert_equal 'data_files', al.controller_name
  end

  test 'explore latest version' do
    data = Factory :small_test_spreadsheet_datafile, policy: Factory(:public_policy)
    get :explore, params: { id: data }
    assert_response :success
  end

  test 'explore earlier version' do
    df = data_files(:downloadable_spreadsheet_data_file)
    assert df.can_edit?
    df.versions.first.content_blob.save # Need to do this as file_size isn't set when loading from fixture
    assert df.can_download?
    get :explore, params: { id: df, version: 1 }

    assert_response :success
  end

  test 'gracefully handles explore with no spreadsheet' do
    df = data_files(:picture)
    get :explore, params: { id: df, version: 1 }
    assert_redirected_to data_file_path(df, version: 1)
    assert flash[:error]
  end

  test 'gracefully handles explore with invalid mime type' do
    df = Factory(:csv_spreadsheet_datafile, policy: Factory(:public_policy))
    df.content_blob.update_column(:content_type, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

    # incorrectly thinks it's excel
    assert df.content_blob.is_excel?

    # check mime type cannot be resolved, otherwise it will autofix without error
    assert_nil df.content_blob.send(:mime_magic_content_type)

    get :explore, params: { id: df, version: 1 }
    assert_redirected_to data_file_path(df, version: 1)
    assert flash[:error]
  end

  test 'correctly displays links in spreadsheet explorer' do
    df = Factory(:data_file,
                 policy: Factory(:public_policy),
                 content_blob: Factory(:small_test_spreadsheet_content_blob, data: File.new("#{Rails.root}/test/fixtures/files/spreadsheet_with_a_link.xls", 'rb').read))
    assert df.can_download?
    get :explore, params: { id: df }
    assert_response :success
    assert_select 'td', text: 'A link to BBC', count: 1
    assert_select 'td a[href=?][target=_blank]', 'http://bbc.co.uk/news', count: 1
  end

  test 'correctly displays rows in spreadsheet explorer' do
    df = Factory(:data_file,
                 policy: Factory(:public_policy),
                 content_blob: Factory(:small_test_spreadsheet_content_blob, data: File.new("#{Rails.root}/test/fixtures/files/spreadsheet_with_a_link.xls", 'rb').read))

    get :explore, params: { id: df }
    assert_response :success

    min_rows = Seek::Data::SpreadsheetExplorerRepresentation::MIN_ROWS
    assert_select 'div#spreadsheet_1' do
      assert_select 'div.row_heading', count: min_rows
      (1..min_rows).each do |i|
        assert_select 'div.row_heading', text: i.to_s, count: 1
      end

      assert_select 'tr', count: min_rows
      assert_select 'td#cell_B2', text: 'A link to BBC', count: 1
    end

    assert_select 'div#spreadsheet_2' do
      assert_select 'div.row_heading', count: min_rows
      (1..min_rows).each do |i|
        assert_select 'div.row_heading', text: i.to_s, count: 1
      end

      assert_select 'tr', count: min_rows
    end
  end

  test 'correctly displays number of rows in spreadsheet explorer' do
    df = Factory(:data_file,
                 policy: Factory(:public_policy),
                 content_blob: Factory(:small_test_spreadsheet_content_blob,
                                       data: File.new("#{Rails.root}/test/fixtures/files/spreadsheet_with_a_link.xls", 'rb').read))

    get :explore, params: { id: df, page_rows: 5 }
    assert_response :success
    assert_select 'div#spreadsheet_1' do
      assert_select 'div.row_heading', count: 5
      assert_select 'tr', count: 5
    end
  end

  test 'correctly displays pagination in spreadsheet explorer' do
    df = Factory(:data_file,
                 policy: Factory(:public_policy),
                 content_blob: Factory(:small_test_spreadsheet_content_blob,
                                       data: File.new("#{Rails.root}/test/fixtures/files/spreadsheet_with_a_link.xls", 'rb').read))

    page_rows = Seek::Data::SpreadsheetExplorerRepresentation::MIN_ROWS / 2 + 1
    get :explore, params: { id: df, page_rows: page_rows }
    assert_response :success

    assert_select 'div#paginate_sheet_1' do
      assert_select 'span.previous_page.disabled', text: /Previous/, count: 1
      assert_select 'em.current', text: '1', count: 1
      assert_select 'a[href=?]', "/data_files/#{df.id}/explore?page=2&page_rows=#{page_rows}&sheet=1", text: '2', count: 1
      assert_select 'a.next_page[href=?]', "/data_files/#{df.id}/explore?page=2&page_rows=#{page_rows}&sheet=1", text: /Next/, count: 1
    end

    assert_select 'div#paginate_sheet_2' do
      assert_select 'span.previous_page.disabled', text: /Previous/, count: 1
      assert_select 'em.current', text: '1', count: 1
      assert_select 'a[href=?]', "/data_files/#{df.id}/explore?page=2&page_rows=#{page_rows}&sheet=2", text: '2', count: 1
      assert_select 'a.next_page[href=?]', "/data_files/#{df.id}/explore?page=2&page_rows=#{page_rows}&sheet=2", text: /Next/, count: 1
    end

    assert_select 'div#paginate_sheet_3' do
      assert_select 'span.previous_page.disabled', text: /Previous/, count: 1
      assert_select 'em.current', text: '1', count: 1
      assert_select 'a[href=?]', "/data_files/#{df.id}/explore?page=2&page_rows=#{page_rows}&sheet=3", text: '2', count: 1
      assert_select 'a.next_page[href=?]', "/data_files/#{df.id}/explore?page=2&page_rows=#{page_rows}&sheet=3", text: /Next/, count: 1
    end
  end

  test 'uploader can publish the private_item when projects associated with the private_item have no gatekeeper' do
    uploader = Factory(:person)
    data_file = Factory(:data_file, contributor: uploader)
    assert_equal Policy::NO_ACCESS, data_file.policy.access_type
    login_as(uploader)

    put :update, params: { id: data_file, data_file: { title: data_file.title }, policy_attributes: { access_type: Policy::VISIBLE } }

    assert_equal Policy::VISIBLE, assigns(:data_file).policy.access_type
    assert_nil flash[:error]
  end

  test 'the person who has the manage right to the private_item, CAN publish the private_item, if no gatekeeper for projects associated with the private_item' do
    person = Factory(:person)
    policy = Factory(:policy)
    Factory(:permission, policy: policy, contributor: person, access_type: Policy::MANAGING)
    data_file = Factory(:data_file, policy: policy)
    assert data_file.asset_gatekeepers.empty?
    assert_equal Policy::NO_ACCESS, data_file.policy.access_type
    login_as(person.user)
    assert data_file.can_manage?

    put :update, params: { id: data_file, data_file: { title: data_file.title }, policy_attributes: { access_type: Policy::VISIBLE } }

    assert_equal Policy::VISIBLE, assigns(:data_file).policy.access_type
    assert_nil flash[:error]
  end

  test 'the person who has the manage right to the private_item, CAN publish the private_item, if the private_item WAS published' do
    person = Factory(:person)
    policy = Factory(:policy)
    Factory(:permission, policy: policy, contributor: person, access_type: Policy::MANAGING)
    data_file = Factory(:data_file, policy: policy)
    assert_equal Policy::NO_ACCESS, data_file.policy.access_type
    login_as(person.user)
    assert data_file.can_manage?

    put :update, params: { id: data_file, data_file: { title: data_file.title }, policy_attributes: { access_type: Policy::VISIBLE } }

    assert_equal Policy::VISIBLE, assigns(:data_file).policy.access_type
    assert_nil flash[:error]
  end

  # TODO: Permission UI testing - Replace these with Jasmine tests
  # test "should enable the policy scope 'all visitor...' when uploader edit the private_item" do
  #   uploader = Factory(:user)
  #   data_file = Factory(:data_file, contributor: uploader)
  #   assert_equal Policy::NO_ACCESS, data_file.policy.access_type
  #   login_as(uploader)
  #   get :edit, id: data_file
  #
  #   assert_select "input[type=radio][id='sharing_scope_4'][value='4'][disabled='true']", count: 0
  # end
  #
  # test "should enable the policy scope 'all visitor...' for the manager in case the asset needs gatekeeper's approval" do
  #   person = Factory(:person)
  #   policy = Factory(:policy)
  #   Factory(:permission, policy: policy, contributor: person, access_type: Policy::MANAGING)
  #
  #   project = Factory(:project)
  #   work_group = Factory(:work_group, project: project)
  #   gatekeeper = Factory(:asset_gatekeeper, group_memberships: [Factory(:group_membership, work_group: work_group)])
  #
  #   data_file = Factory(:data_file, policy: policy, project_ids: [project.id])
  #   assert_equal Policy::NO_ACCESS, data_file.policy.access_type
  #   login_as(person.user)
  #   assert data_file.can_manage?
  #   assert data_file.can_publish?
  #   assert data_file.gatekeeper_required?
  #
  #   get :edit, id: data_file
  #
  #   assert_select "input[type=radio][id='sharing_scope_4'][value='4'][disabled='true']", count: 0
  # end
  #
  # test "should enable the policy scope 'all visitor...' for the manager in case the asset does not need gatekeeper's approval" do
  #   person = Factory(:person)
  #   policy = Factory(:policy, access_type: Policy::ACCESSIBLE)
  #   Factory(:permission, policy: policy, contributor: person, access_type: Policy::MANAGING)
  #   data_file = Factory(:data_file, policy: policy)
  #   assert_equal Policy::ACCESSIBLE, data_file.policy.access_type
  #   login_as(person.user)
  #   assert data_file.can_manage?
  #
  #   get :edit, id: data_file
  #
  #   assert_select "input[type=radio][id='sharing_scope_4'][value='4'][disabled='true']", count: 0
  # end

  test 'should show the latest version if the params[:version] is not specified' do
    data_file = data_files(:editable_data_file)
    get :show, params: { id: data_file }
    assert_response :success
    assert_nil flash[:error]

    logout
    published_data_file = Factory(:data_file, policy: Factory(:public_policy))
    get :show, params: { id: published_data_file }
    assert_response :success
    assert_nil flash[:error]
  end

  test 'should show the correct version' do
    data_file = data_files(:downloadable_spreadsheet_data_file)
    get :show, params: { id: data_file, version: 1 }
    assert_response :success
    assert_nil flash[:error]

    get :show, params: { id: data_file, version: 2 }
    assert_response :success
    assert_nil flash[:error]
  end

  test 'should show error for the incorrect version' do
    data_file = data_files(:editable_data_file)
    get :show, params: { id: data_file, version: 2 }
    assert_redirected_to root_path
    assert_not_nil flash[:error]
  end

  test 'should not show private data file to logged out user' do
    df = Factory :data_file
    logout
    get :show, params: { id: df }
    assert_response :forbidden
  end

  test 'should not show private data file to another user' do
    df = Factory :data_file, contributor: Factory(:person)
    get :show, params: { id: df }
    assert_response :forbidden
  end

  test "should show error for the anonymous user who tries to view 'registered-users-only' version" do
    published_data_file = Factory(:data_file, policy: Factory(:public_policy))

    published_data_file.save_as_new_version
    Factory(:content_blob, asset: published_data_file, asset_version: published_data_file.version)
    published_data_file.reload

    disable_authorization_checks do
      published_data_file.find_version(1).update_attributes!(visibility: :registered_users)
      published_data_file.find_version(2).update_attributes!(visibility: :public)
    end

    logout
    get :show, params: { id: published_data_file, version: 1 }
    assert_redirected_to root_path
    assert_not_nil flash[:error]

    clear_flash(:error)
    get :show, params: { id: published_data_file, version: 2 }
    assert_response :success
    assert_nil flash[:error]

    login_as(Factory(:user_not_in_project))
    get :show, params: { id: published_data_file, version: 1 }
    assert_redirected_to root_path
    assert_not_nil flash[:error]

    clear_flash(:error)
    get :show, params: { id: published_data_file, version: 2 }
    assert_response :success
    assert_nil flash[:error]
  end

  test 'should set the other creators ' do
    data_file = data_files(:picture)
    assert data_file.can_manage?, 'The data file must be manageable for this test to succeed'
    put :update, params: { id: data_file, data_file: { other_creators: 'marry queen' } }
    data_file.reload
    assert_equal 'marry queen', data_file.other_creators
  end

  test 'should show the other creators on the data file index' do
    data_file = data_files(:picture)
    data_file.other_creators = 'another creator'
    data_file.save
    get :index, params: { page: 'P' }

    assert_select 'p.list_item_attribute', text: /another creator/, count: 1
  end

  test 'should show the other creators in uploader and creators box' do
    data_file = data_files(:picture)
    data_file.other_creators = 'another creator'
    data_file.save
    get :show, params: { id: data_file }

    assert_select '#author-box .additional-credit', text: 'another creator', count: 1
  end

  # TODO: Permission UI testing - Replace this with a Jasmine test
  # test 'should select the correct sharing access_type when updating the datafile' do
  #   df = Factory(:data_file, policy: Factory(:policy, sharing_scope: Policy::EVERYONE, access_type: Policy::ACCESSIBLE))
  #   login_as(df.contributor)
  #
  #   get :edit, id: df.id
  #   assert_response :success
  #
  #   assert_select 'select#access_type_select_4' do
  #     assert_select "option[selected='selected']", text: /#{I18n.t("access.accessible_downloadable")}/
  #   end
  # end

  test 'you should not subscribe to the asset created by the person whose projects overlap with you' do
    current_person = User.current_user.person
    proj = current_person.projects.first
    current_person.project_subscriptions.create project: proj, frequency: 'weekly'
    a_person = Factory(:person)
    a_person.project_subscriptions.create project: a_person.projects.first, frequency: 'weekly'
    current_person.group_memberships << Factory(:group_membership, work_group: Factory(:work_group, project: a_person.projects.first))
    assert current_person.save
    assert current_person.reload.projects.include?(a_person.projects.first)
    assert_empty Subscription.all

    df_param = { title: 'Test', project_ids: [proj.id] }
    blob = { data: picture_file }
    assert_enqueued_with(job: SetSubscriptionsForItemJob) do
      post :create, params: { data_file: df_param, content_blobs: [blob], policy_attributes: valid_sharing }
    end
    df = assigns(:data_file)

    SetSubscriptionsForItemJob.perform_now(df, df.projects)

    assert df.subscribed?(current_person)
    refute df.subscribed?(a_person)
    assert_equal 1, current_person.subscriptions.count
    assert_equal proj, current_person.subscriptions.first.project_subscription.project
  end

  test 'project data files through nested routing' do
    assert_routing 'projects/2/data_files', controller: 'data_files', action: 'index', project_id: '2'
    df = Factory(:data_file, policy: Factory(:public_policy))
    project = df.projects.first
    df2 = Factory(:data_file, policy: Factory(:public_policy))
    get :index, params: { project_id: project.id }
    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', data_file_path(df), text: df.title
      assert_select 'a[href=?]', data_file_path(df2), text: df2.title, count: 0
    end
  end

  test 'workflow data files through nested routing' do
    assert_routing 'workflows/2/data_files', controller: 'data_files', action: 'index', workflow_id: '2'
    workflow = Factory(:workflow, contributor: User.current_user.person)
    df = Factory(:data_file, policy: Factory(:public_policy), workflows: [workflow], contributor: User.current_user.person)
    df2 = Factory(:data_file, policy: Factory(:public_policy), contributor: User.current_user.person)
    get :index, params: { workflow_id: workflow.id }
    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', data_file_path(df), text: df.title
      assert_select 'a[href=?]', data_file_path(df2), text: df2.title, count: 0
    end
  end

  test 'filtered data files for non existent study' do
    Factory :data_file # needs a data file to be sure that the problem being fixed is triggered
    study_id = 999
    assert_nil Study.find_by_id(study_id)
    get :index, params: { study_id: study_id }
    assert_response :not_found
  end

  test 'filtered data files for non existent project' do
    Factory :data_file # needs a data file to be sure that the problem being fixed is triggered
    project_id = 999
    assert_nil Project.find_by_id(project_id)
    get :index, params: { project_id: project_id }
    assert_response :not_found
  end

  test 'handles nil description' do
    df = Factory(:data_file, description: nil, policy: Factory(:public_policy))

    get :show, params: { id: df }
    assert_response :success
  end

  test 'description formatting' do
    desc = 'This is <b>Bold</b> - this is <em>emphasised</em> - this is super<sup>script</sup> - '
    desc << 'this is link to google: http://google.com - '
    desc << "this is some nasty javascript <script>alert('fred');</script>"

    df = Factory(:data_file, description: desc, policy: Factory(:public_policy))

    get :show, params: { id: df }
    assert_response :success
    assert_select 'div#description' do
      assert_select 'p'
      assert_select 'b', text: 'Bold'
      assert_select 'em', text: 'emphasised'
      assert_select 'sup', text: 'script'
      assert_select 'script', count: 0
      assert_select 'a[href=?]', 'http://google.com', text: 'http://google.com'
    end
  end

  test 'filter by people, including creators, using nested routes' do
    assert_routing 'people/7/presentations', controller: 'presentations', action: 'index', person_id: '7'

    person1 = Factory(:person)
    person2 = Factory(:person)

    df1 = Factory(:data_file, contributor: person1, policy: Factory(:public_policy))
    df2 = Factory(:data_file, contributor: person2, policy: Factory(:public_policy))

    df3 = Factory(:data_file, contributor: Factory(:person), creators: [person1], policy: Factory(:public_policy))
    df4 = Factory(:data_file, contributor: Factory(:person), creators: [person2], policy: Factory(:public_policy))

    get :index, params: { person_id: person1.id }
    assert_response :success

    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', data_file_path(df1), text: df1.title
      assert_select 'a[href=?]', data_file_path(df3), text: df3.title

      assert_select 'a[href=?]', data_file_path(df2), text: df2.title, count: 0
      assert_select 'a[href=?]', data_file_path(df4), text: df4.title, count: 0
    end
  end

  test 'edit should include tags element' do
    df = Factory(:data_file, policy: Factory(:public_policy))
    get :edit, params: { id: df.id }
    assert_response :success

    assert_select 'div.panel-heading', text: /Tags/, count: 1
    assert_select 'input#tag_list', count: 1
  end

  test 'register form should include tags element' do
    register_content_blob
    assert_response :success
    assert_select 'div.panel-heading', text: /Tags/, count: 1
    assert_select 'input#tag_list', count: 1
  end

  test 'edit should include not include tags element when tags disabled' do
    with_config_value :tagging_enabled, false do
      df = Factory(:data_file, policy: Factory(:public_policy))
      get :edit, params: { id: df.id }
      assert_response :success

      assert_select 'div.panel-heading', text: /Tags/, count: 0
      assert_select 'input#tag_list', count: 0
    end
  end

  test 'register form should not include tags element when tags disabled' do
    with_config_value :tagging_enabled, false do
      register_content_blob
      assert_response :success
      assert_select 'div.panel-heading', text: /Tags/, count: 0
      assert_select 'input#tag_list', count: 0
    end
  end

  test 'get data_file as json' do
    df = Factory(:data_file, policy: Factory(:public_policy), title: 'fish flop', description: 'testing json description')
    get :show, params: { id: df, format: 'json' }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal df.id, json['data']['id'].to_i
    assert_equal 'fish flop', json['data']['attributes']['title']
    assert_equal 'testing json description', json['data']['attributes']['description']
    assert_equal df.version, json['data']['attributes']['version']
  end

  test 'landing page for hidden private_item' do
    df = Factory(:data_file, policy: Factory(:private_policy), title: 'fish flop', description: 'testing json description')
    assert !df.can_view?

    get :show, params: { id: df }
    assert_response :forbidden
    assert_select 'h2', text: /The #{I18n.t('data_file')} is not visible to you./

    refute df.can_see_hidden_item?(User.current_user.person)
    assert_select 'a[href=?]', person_path(df.contributor), count: 0
  end

  test 'landing page for hidden private_item with the contributor contact' do
    df = Factory(:data_file, policy: Factory(:private_policy), title: 'fish flop', description: 'testing json description')

    project = df.projects.first
    work_group = Factory(:work_group, project: project)
    person = Factory(:person_in_project, group_memberships: [Factory(:group_membership, work_group: work_group)])
    user = Factory(:user, person: person)

    login_as(user)

    assert !df.can_view?
    assert df.can_see_hidden_item?(user.person)

    get :show, params: { id: df }
    assert_response :forbidden
    assert_select 'h2', text: /The #{I18n.t('data_file')} is not visible to you./

    assert_select 'a[href=?]', person_path(df.contributor)
  end

  test 'landing page for hidden private_item which DOI was minted' do
    df = Factory(:data_file, policy: Factory(:private_policy), title: 'fish flop', description: 'testing json description')
    comment = 'the paper was retracted'
    AssetDoiLog.create(asset_type: df.class.name, asset_id: df.id, asset_version: df.version, action: AssetDoiLog::MINT)
    AssetDoiLog.create(asset_type: df.class.name, asset_id: df.id, asset_version: df.version, action: AssetDoiLog::UNPUBLISH, comment: comment)

    assert !df.can_view?
    assert AssetDoiLog.was_doi_minted_for?(df.class.name, df.id, df.version)

    get :show, params: { id: df }
    assert_response :forbidden
    assert_select 'p.comment', text: /#{comment}/
  end

  test 'landing page for non-existing private_item' do
    get :show, params: { id: 123 }
    assert_response :not_found
    assert_select 'h1', text: '404'
    assert_select 'h2', text: 'The requested page or resource does not exist.'
  end

  test 'landing page for deleted private_item which DOI was minted' do
    comment = 'the paper was restracted'
    klass = 'DataFile'
    id = 123
    version = 1
    AssetDoiLog.create(asset_type: klass, asset_id: id, asset_version: version, action: AssetDoiLog::MINT)
    AssetDoiLog.create(asset_type: klass, asset_id: id, asset_version: version, action: AssetDoiLog::DELETE, comment: comment)
    assert AssetDoiLog.was_doi_minted_for?(klass, id, version)
    get :show, params: { id: id, version: version }
    assert_response :not_found
    assert_select 'p[class=comment]', text: /#{comment}/
  end

  test 'should create cache job for small file' do
    mock_http
    params = { data_file: {
        title: 'Small File',
        project_ids: [projects(:sysmo_project).id]
    },
               content_blobs: [{
                                   data_url: 'http://mockedlocation.com/small.txt',
                                   make_local_copy: '0'
                               }],
               policy_attributes: valid_sharing }

    assert_enqueued_jobs(1, only: RemoteContentFetchingJob) do
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, params: params
        end
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    blob = assigns(:data_file).content_blob
    assert blob.cachable?
    assert !blob.url.blank?
    assert_equal 'small.txt', blob.original_filename
    assert_equal 'text/plain', blob.content_type
    assert_equal 100, blob.file_size
    assert blob.remote_content_fetch_task&.pending?
  end

  test 'should not create cache job if setting disabled' do
    mock_http
    params = { data_file: {
        title: 'Small File',
        project_ids: [projects(:sysmo_project).id]
    },
               content_blobs: [{
                                   data_url: 'http://mockedlocation.com/small.txt',
                                   make_local_copy: '0'
                               }],
               policy_attributes: valid_sharing }

    with_config_value(:cache_remote_files, false) do
      assert_no_enqueued_jobs(only: RemoteContentFetchingJob) do
        assert_difference('DataFile.count') do
          assert_difference('ContentBlob.count') do
            post :create, params: params
          end
        end
      end

      assert_redirected_to data_file_path(assigns(:data_file))
      blob = assigns(:data_file).content_blob
      assert !blob.cachable?
      assert !blob.url.blank?
      assert_equal 'small.txt', blob.original_filename
      assert_equal 'text/plain', blob.content_type
      assert_equal 100, blob.file_size
      refute blob.remote_content_fetch_task&.pending?
    end
  end

  test "should not create cache job if setting disabled even if user requests 'make_local_copy'" do
    mock_http
    params = { data_file: {
        title: 'Big File',
        project_ids: [projects(:sysmo_project).id]
    },
               content_blobs: [{
                                   data_url: 'http://mockedlocation.com/big.txt',
                                   original_filename: '',
                                   make_local_copy: '1'
                               }],
               policy_attributes: valid_sharing }
    with_config_value(:cache_remote_files, false) do
      assert_no_enqueued_jobs(only: RemoteContentFetchingJob) do
        assert_difference('DataFile.count') do
          assert_difference('ContentBlob.count') do
            post :create, params: params
          end
        end
      end

      assert_redirected_to data_file_path(assigns(:data_file))
      blob = assigns(:data_file).content_blob
      refute blob.external_link?
      assert !blob.cachable?
      assert !blob.url.blank?
      assert_equal 'big.txt', blob.original_filename
      assert_equal 'text/plain', blob.content_type
      assert_equal 5000, blob.file_size
      refute blob.remote_content_fetch_task&.pending?
    end
  end

  test 'should not automatically create cache job for large file' do
    mock_http
    params = { data_file: {
        title: 'Big File',
        project_ids: [projects(:sysmo_project).id]
    },
               content_blobs: [{
                                   data_url: 'http://mockedlocation.com/big.txt',
                                   make_local_copy: '0'
                               }],
               policy_attributes: valid_sharing }

    assert_no_enqueued_jobs(only: RemoteContentFetchingJob) do
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, params: params
        end
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    blob = assigns(:data_file).content_blob
    refute blob.make_local_copy
    refute blob.cachable?
    refute blob.url.blank?
    assert_equal 'big.txt', blob.original_filename
    assert_equal 'text/plain', blob.content_type
    assert_equal 5000, blob.file_size
    refute blob.remote_content_fetch_task&.pending?
  end

  test 'should not automatically create cache job for webpage links' do
    mock_http
    params = { data_file: {
        title: 'My Fav Website',
        project_ids: [projects(:sysmo_project).id]
    },
               content_blobs: [{
                                   data_url: 'http://mockedlocation.com'
                               }],
               policy_attributes: valid_sharing }

    assert_no_enqueued_jobs(only: RemoteContentFetchingJob) do
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, params: params
        end
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    blob = assigns(:data_file).content_blob
    assert !blob.cachable?
    assert !blob.url.blank?
    assert blob.original_filename.blank?
    assert_equal 'text/html', blob.content_type
    refute blob.remote_content_fetch_task&.pending?
  end

  test "should create cache job for large file if user requests 'make_local_copy'" do
    mock_http
    params = { data_file: {
        title: 'Big File',
        project_ids: [projects(:sysmo_project).id]
    },
               content_blobs: [{
                                   data_url: 'http://mockedlocation.com/big.txt',
                                   make_local_copy: '1'
                               }],
               policy_attributes: valid_sharing
    }

    assert_enqueued_jobs(1, only: RemoteContentFetchingJob) do
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, params: params
        end
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    refute_nil assigns(:data_file).content_blob
    blob = assigns(:data_file).content_blob
    refute blob.external_link?
    assert !blob.cachable?
    assert !blob.url.blank?
    assert_equal 'big.txt', blob.original_filename
    assert_equal 'text/plain', blob.content_type
    assert_equal 5000, blob.file_size
    assert blob.remote_content_fetch_task&.pending?
  end

  test 'should create data file for remote URL that does not respond to HEAD' do
    mock_http
    params = { data_file: {
        title: 'No Head File',
        project_ids: [projects(:sysmo_project).id]
    },
               content_blobs: [{
                                   data_url: 'http://mockedlocation.com/nohead.txt',
                                   make_local_copy: '1'
                               }],
               policy_attributes: valid_sharing }

    assert_enqueued_jobs(1, only: RemoteContentFetchingJob) do
      assert_difference('DataFile.count') do
        assert_difference('ContentBlob.count') do
          post :create, params: params
        end
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    refute_nil assigns(:data_file).content_blob
    blob = assigns(:data_file).content_blob
    refute blob.external_link?
    assert !blob.cachable?
    assert !blob.url.blank?
    assert_equal 'nohead.txt', blob.original_filename
    assert_equal 'text/plain', blob.content_type
    assert_equal 5000, blob.file_size
    assert blob.remote_content_fetch_task&.pending?
  end

  test 'should create data file for remote URL with a space at the end' do
    mock_http
    params = { data_file: {
        title: 'Remote File',
        project_ids: [projects(:sysmo_project).id]
    },
               content_blobs: [{
                                   data_url: 'http://mockedlocation.com/txt_test.txt ',
                                   make_local_copy: '1'
                               }],
               policy_attributes: valid_sharing }

    assert_difference('DataFile.count') do
      assert_difference('ContentBlob.count') do
        post :create, params: params
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal 'http://mockedlocation.com/txt_test.txt', assigns(:data_file).content_blob.url
  end

  test 'should create data file for remote URL with no scheme' do
    mock_http
    params = { data_file: {
        title: 'Remote File',
        project_ids: [projects(:sysmo_project).id]
    },
               content_blobs: [{
                                   data_url: 'mockedlocation.com/txt_test.txt',
                                   make_local_copy: '1'
                               }],
               policy_attributes: valid_sharing }

    assert_difference('DataFile.count') do
      assert_difference('ContentBlob.count') do
        post :create, params: params
      end
    end

    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal 'http://mockedlocation.com/txt_test.txt', assigns(:data_file).content_blob.url
  end

  test 'should display null license text' do
    df = Factory :data_file, policy: Factory(:public_policy)

    get :show, params: { id: df }

    assert_select '.panel .panel-body span#null_license', text: I18n.t('null_license')
  end

  test 'should display license' do
    df = Factory :data_file, license: 'CC-BY-4.0', policy: Factory(:public_policy)

    get :show, params: { id: df }

    assert_select '.panel .panel-body a', text: 'Creative Commons Attribution 4.0'
  end

  test 'should display license for current version' do
    df = Factory :data_file, license: 'CC-BY-4.0', policy: Factory(:public_policy)
    dfv = Factory :data_file_version_with_blob, data_file: df

    df.update_attributes license: 'CC0-1.0'

    get :show, params: { id: df, version: 1 }
    assert_response :success
    assert_select '.panel .panel-body a', text: 'Creative Commons Attribution 4.0'

    get :show, params: { id: df, version: dfv.version }
    assert_response :success
    assert_select '.panel .panel-body a', text: 'CC0 1.0'
  end

  test 'should update license' do
    refute_nil user = User.current_user
    df = Factory(:data_file, contributor: user.person)

    assert_nil df.license

    put :update, params: { id: df, data_file: { license: 'CC-BY-SA-4.0' } }

    assert_response :redirect

    get :show, params: { id: df }
    assert_select '.panel .panel-body a', text: 'Creative Commons Attribution Share-Alike 4.0'
    assert_equal 'CC-BY-SA-4.0', assigns(:data_file).license
  end

  test 'check correct license pre-selected' do
    df = Factory :data_file, license: 'CC-BY-SA-4.0', policy: Factory(:public_policy)

    get :edit, params: { id: df }
    assert_response :success
    assert_select '#license-select option[selected=?]', 'selected', text: 'Creative Commons Attribution Share-Alike 4.0'

    df2 = Factory :data_file, license: nil, policy: Factory(:public_policy)

    get :edit, params: { id: df2 }
    assert_response :success
    assert_select '#license-select option[selected=?]', 'selected', text: I18n.t('null_license')

    register_content_blob
    assert_response :success
    assert_select '#license-select option[selected=?]', 'selected', text: 'Creative Commons Attribution 4.0'
  end

  test 'can disambiguate sample type' do
    create_sample_attribute_type
    person = Factory(:project_administrator)
    login_as(person)

    data_file = Factory :data_file, content_blob: Factory(:sample_type_populated_template_content_blob),
                        policy: Factory(:private_policy), contributor: person
    refute data_file.sample_template?
    assert_empty data_file.possible_sample_types

    sample_type = SampleType.new title: 'visible1', uploaded_template: true, project_ids: [person.projects.first.id], contributor: person
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    # this is to force the full name to be 2 words, so that one row fails
    sample_type.sample_attributes.first.sample_attribute_type = Factory(:full_name_sample_attribute_type)
    sample_type.sample_attributes[1].sample_attribute_type = Factory(:datetime_sample_attribute_type)
    sample_type.save!
    assert sample_type.can_view?

    sample_type = SampleType.new title: 'visible2', uploaded_template: true, project_ids: [person.projects.first.id], contributor: person
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    # this is to force the full name to be 2 words, so that one row fails
    sample_type.sample_attributes.first.sample_attribute_type = Factory(:full_name_sample_attribute_type)
    sample_type.sample_attributes[1].sample_attribute_type = Factory(:datetime_sample_attribute_type)
    sample_type.save!
    assert sample_type.can_view?

    # this is a private one, from another project, and shouldn't show up
    person2 = Factory(:person)
    sample_type = SampleType.new title: 'private', uploaded_template: true, projects: person2.projects,contributor:person2
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    # this is to force the full name to be 2 words, so that one row fails
    sample_type.sample_attributes.first.sample_attribute_type = Factory(:full_name_sample_attribute_type)
    sample_type.sample_attributes[1].sample_attribute_type = Factory(:datetime_sample_attribute_type)
    disable_authorization_checks{sample_type.save!}
    refute sample_type.can_view?

    get :select_sample_type, params: { id: data_file }

    assert_select 'select[name=sample_type_id] option', count: 2
    assert_select 'select[name=sample_type_id] option', text:'visible1'
    assert_select 'select[name=sample_type_id] option', text:'visible2'
    assert_select 'select[name=sample_type_id] option', text:'private',count:0
  end

  test 'filtering for sample association form' do
    person = Factory(:person)
    d1 = Factory(:data_file, projects: person.projects, contributor: person, policy: Factory(:public_policy), title: 'fish')
    d2 = Factory(:data_file, projects: person.projects, contributor: person, policy: Factory(:public_policy), title: 'frog')
    d3 = Factory(:data_file, projects: person.projects, contributor: person, policy: Factory(:public_policy), title: 'banana')
    d4 = Factory(:data_file, projects: person.projects, contributor: person, policy: Factory(:public_policy), title: 'no samples')
    [d1, d2, d3].each do |data_file|
      Factory(:sample, originating_data_file_id: data_file.id, contributor: person)
    end
    login_as(person.user)

    get :filter, params: { filter: 'no' }
    assert_select 'a', text: /no samples/, count: 1
    assert_response :success

    get :filter, params: { filter: '', with_samples: 'true' }
    assert_select 'a', count: 3
    assert_select 'a', text: /no samples/, count: 0
    assert_response :success

    get :filter, params: { filter: 'f', with_samples: 'true' }
    assert_select 'a', count: 2
    assert_select 'a', text: /fish/
    assert_select 'a', text: /frog/

    get :filter, params: { filter: 'fi', with_samples: 'true' }
    assert_select 'a', count: 1
    assert_select 'a', text: /fish/
  end


  test 'filtering using other fields in association form' do
    person = Factory(:person)
    project1 = person.projects.first

    person2 = Factory(:person)
    project2 = person2.projects.first

    d1 = Factory(:data_file, projects: [project1], contributor: person, policy: Factory(:public_policy), title: 'datax1a')
    d2 = Factory(:data_file, projects: [project1], contributor: person, policy: Factory(:public_policy), title: 'datax1b')
    d3 = Factory(:data_file, projects: [project2], contributor: person2, policy: Factory(:public_policy), title: 'datax2a')
    d4 = Factory(:data_file, projects: [project2], contributor: person2, policy: Factory(:public_policy), title: 'datax2b', simulation_data: true)

    login_as(person.user)

    get :filter, params: { filter: 'datax' }
    assert_select 'a', count: 2
    assert_select 'a', text: /datax1./, count: 2
    assert_select 'a', text: /datax2./, count: 0
    assert_response :success

    get :filter, params: { filter: 'datax', all_projects: 'true' }
    assert_select 'a', count: 4
    assert_select 'a', text: /datax./, count: 4
    assert_response :success

    get :filter, params: { filter: 'datax', all_projects: 'true', simulation_data: 'true' }
    assert_select 'a', count: 1
    assert_select 'a', text: /datax2b/, count: 1
    assert_response :success

    get :filter, params: { filter: 'datax', simulation_data: 'true' }
    assert response.body.blank?
    assert_response :success
  end

  test 'programme data files through nested routing' do
    assert_routing 'programmes/2/data_files', controller: 'data_files', action: 'index', programme_id: '2'
    programme = Factory(:programme)
    data_file = Factory(:data_file, projects: programme.projects, policy: Factory(:public_policy))
    data_file2 = Factory(:data_file, policy: Factory(:public_policy))

    get :index, params: { programme_id: programme.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', data_file_path(data_file), text: data_file.title
      assert_select 'a[href=?]', data_file_path(data_file2), text: data_file2.title, count: 0
    end
  end

  test 'should get table view for data file' do
    data_file = Factory(:data_file, policy: Factory(:private_policy))
    sample_type = Factory(:simple_sample_type)
    3.times do
      Factory(:sample, sample_type: sample_type, contributor: data_file.contributor, policy: Factory(:private_policy),
              originating_data_file: data_file)
    end
    login_as(data_file.contributor)

    get :samples_table, params: { format: :json, id: data_file.id }

    assert_response :success

    json = JSON.parse(@response.body)
    assert_equal 3, json['data'].length
  end

  test 'should not get table view for private data file if unauthorized' do
    data_file = Factory(:data_file, policy: Factory(:private_policy))
    sample_type = Factory(:simple_sample_type)
    3.times do
      Factory(:sample, sample_type: sample_type, contributor: data_file.contributor, policy: Factory(:private_policy),
              originating_data_file: data_file)
    end

    get :samples_table, params: { format: :json, id: data_file.id }

    assert_response :forbidden
  end

  test "can't extract from data file if no permissions" do
    create_sample_attribute_type
    person = Factory(:project_administrator)
    another_person = Factory(:person)
    login_as(person)

    data_file = Factory :data_file, content_blob: Factory(:sample_type_populated_template_content_blob), policy: Factory(:private_policy), contributor: person
    refute data_file.sample_template?
    assert_empty data_file.possible_sample_types

    sample_type = SampleType.new title: 'from template', project_ids: [person.projects.first.id], contributor: person
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    # this is to force the full name to be 2 words, so that one row fails
    sample_type.sample_attributes.first.sample_attribute_type = Factory(:full_name_sample_attribute_type)
    sample_type.sample_attributes[1].sample_attribute_type = Factory(:datetime_sample_attribute_type)
    sample_type.save!

    login_as(another_person)

    assert_no_difference('Sample.count') do
      post :extract_samples, params: { id: data_file, confirm: 'true' }
    end

    assert_redirected_to data_file_path(data_file)
    assert_not_empty flash[:error]
  end

  test 'strain samples successfully extracted from spreadsheet' do
    create_sample_attribute_type
    person = Factory(:project_administrator)
    login_as(person)

    data_file = Factory :data_file, content_blob: Factory(:strain_sample_data_content_blob),
                        policy: Factory(:private_policy), contributor: person
    refute data_file.sample_template?
    assert_empty data_file.possible_sample_types

    sample_type = SampleType.new title: 'from template', uploaded_template: true, project_ids: [person.projects.first.id], contributor: person
    sample_type.content_blob = Factory(:strain_sample_data_content_blob)
    sample_type.build_attributes_from_template
    attribute_type = sample_type.sample_attributes[-2]
    attribute_type.sample_attribute_type = Factory(:strain_sample_attribute_type)
    attribute_type.required = true
    attribute_type = sample_type.sample_attributes[-1]
    attribute_type.sample_attribute_type = Factory(:strain_sample_attribute_type)
    attribute_type.required = false
    sample_type.save!

    assert_difference('Sample.count', 3) do
      post :extract_samples, params: { id: data_file.id, confirm: 'true' }
    end

    assert(samples = assigns(:samples))
    assert_equal 3, samples.count
    assert_equal samples.sort, data_file.extracted_samples.sort
  end

  test 'extract from data file' do
    create_sample_attribute_type
    person = Factory(:project_administrator)
    login_as(person)

    data_file = Factory :data_file, content_blob: Factory(:sample_type_populated_template_content_blob),
                        policy: Factory(:private_policy), contributor: person
    refute data_file.sample_template?
    assert_empty data_file.possible_sample_types

    sample_type = SampleType.new title: 'from template', uploaded_template: true, project_ids: [person.projects.first.id], contributor: person
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    # this is to force the full name to be 2 words, so that one row fails
    sample_type.sample_attributes.first.sample_attribute_type = Factory(:full_name_sample_attribute_type)
    sample_type.sample_attributes[1].sample_attribute_type = Factory(:datetime_sample_attribute_type)
    sample_type.save!

    assert_difference('Sample.count', 3) do
      post :extract_samples, params: { id: data_file.id, confirm: 'true' }
    end

    assert_redirected_to data_file_path(data_file)

    assert(samples = assigns(:samples))
    assert_equal 3, samples.count
    assert_not_includes samples.map { |s| s.get_attribute_value('full name') }, 'Bob'

    samples.each do |sample|
      assert_equal data_file, sample.originating_data_file
    end

    data_file.reload

    assert_equal samples.sort, data_file.extracted_samples.sort
  end

  test 'extract from data file with multiple matching sample types redirects to selection page' do
    create_sample_attribute_type
    person = Factory(:project_administrator)
    login_as(person)

    data_file = Factory :data_file, content_blob: Factory(:sample_type_populated_template_content_blob),
                        policy: Factory(:private_policy), contributor: person
    refute data_file.sample_template?
    assert_empty data_file.possible_sample_types

    # First matching type
    sample_type = SampleType.new title: 'from template 1', uploaded_template: true, project_ids: [person.projects.first.id], contributor: person
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    # this is to force the full name to be 2 words, so that one row fails
    sample_type.sample_attributes.first.sample_attribute_type = Factory(:full_name_sample_attribute_type)
    sample_type.sample_attributes[1].sample_attribute_type = Factory(:datetime_sample_attribute_type)
    sample_type.save!

    # Second matching type
    sample_type = SampleType.new title: 'from template 2', uploaded_template: true, project_ids: [person.projects.first.id], contributor: person
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    # this is to force the full name to be 2 words, so that one row fails
    sample_type.sample_attributes.first.sample_attribute_type = Factory(:full_name_sample_attribute_type)
    sample_type.sample_attributes[1].sample_attribute_type = Factory(:datetime_sample_attribute_type)
    sample_type.save!

    assert_difference('Sample.count', 0) do
      post :extract_samples, params: { id: data_file.id }
    end

    assert_redirected_to select_sample_type_data_file_path(data_file) # Test for this is in data_files_controller_test
  end

  test 'show data file with "extract samples" button' do
    create_sample_attribute_type
    person = Factory(:project_administrator)
    login_as(person)

    data_file = Factory :data_file, content_blob: Factory(:sample_type_populated_template_content_blob),
                        policy: Factory(:private_policy), contributor: person
    refute data_file.sample_template?
    assert_empty data_file.possible_sample_types

    sample_type = SampleType.new title: 'from template', uploaded_template: true, project_ids: [person.projects.first.id], contributor: person
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    sample_type.save!

    get :show, params: { id: data_file.id }

    assert_select 'a.btn', text: /Extract samples/
  end

  test 'show data file with sample extraction in progress' do
    create_sample_attribute_type
    person = Factory(:project_administrator)
    login_as(person)

    data_file = Factory :data_file, content_blob: Factory(:sample_type_populated_template_content_blob),
                        policy: Factory(:private_policy), contributor: person
    refute data_file.sample_template?
    assert_empty data_file.possible_sample_types

    sample_type = SampleType.new title: 'from template', uploaded_template: true, project_ids: [person.projects.first.id], contributor: person
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    sample_type.save!

    data_file.tasks.create!(key: 'sample_extraction', status: Task::STATUS_QUEUED)

    get :show, params: { id: data_file.id }

    assert_select '#sample-extraction-status', text: /Queued/
  end

  test 'show data file with sample extraction done and ready for review' do
    create_sample_attribute_type
    person = Factory(:project_administrator)
    login_as(person)

    data_file = Factory :data_file, content_blob: Factory(:sample_type_populated_template_content_blob),
                        policy: Factory(:private_policy), contributor: person
    refute data_file.sample_template?
    assert_empty data_file.possible_sample_types

    sample_type = SampleType.new title: 'from template', uploaded_template: true, project_ids: [person.projects.first.id], contributor: person
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    sample_type.save!

    Seek::Samples::Extractor.new(data_file, sample_type).extract
    data_file.tasks.create!(key: 'sample_extraction', status: Task::STATUS_DONE)

    get :show, params: { id: data_file.id }

    assert_select '#sample-extraction-status a[href=?]', confirm_extraction_data_file_path(data_file)
  end

  test 'extract from data file queues job' do
    create_sample_attribute_type
    person = Factory(:project_administrator)
    login_as(person)

    data_file = Factory :data_file, content_blob: Factory(:sample_type_populated_template_content_blob),
                        policy: Factory(:private_policy), contributor: person
    refute data_file.sample_template?
    assert_empty data_file.possible_sample_types

    sample_type = SampleType.new title: 'from template', uploaded_template: true, project_ids: [person.projects.first.id], contributor: person
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    # this is to force the full name to be 2 words, so that one row fails
    sample_type.sample_attributes.first.sample_attribute_type = Factory(:full_name_sample_attribute_type)
    sample_type.sample_attributes[1].sample_attribute_type = Factory(:datetime_sample_attribute_type)
    sample_type.save!

    assert_no_difference('Sample.count') do
      assert_difference('Task.count') do
        assert_enqueued_jobs(1, only: SampleDataExtractionJob) do
          post :extract_samples, params: { id: data_file.id }

          assert data_file.reload.sample_extraction_task&.pending?
        end
      end
    end

    assert_redirected_to data_file_path(data_file)
  end

  test "can't extract from data file if samples already extracted" do
    create_sample_attribute_type
    person = Factory(:project_administrator)
    login_as(person)

    data_file = Factory :data_file, content_blob: Factory(:sample_type_populated_template_content_blob),
                        policy: Factory(:private_policy),
                        contributor: person
    refute data_file.sample_template?
    assert_empty data_file.possible_sample_types

    sample_type = SampleType.new title: 'from template', uploaded_template: true, project_ids: [person.projects.first.id], contributor: person
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    sample_type.save!
    extracted_sample = Factory(:sample, data: { 'full name': 'John Wayne' },
                               sample_type: sample_type,
                               originating_data_file: data_file, contributor: person),

        assert_no_difference('Sample.count') do
          post :extract_samples, params: { id: data_file, confirm: 'true' }
        end

    assert_redirected_to data_file_path(data_file)
    assert_not_empty flash[:error]
    assert flash[:error].include?('Already extracted')
  end

  test 'can get citation for data file with DOI' do
    doi_citation_mock
    data_file = Factory(:data_file, policy: Factory(:public_policy))

    login_as(data_file.contributor)

    get :show, params: { id: data_file }
    assert_response :success
    assert_select '#citation', text: /Bacall, F/, count:0

    data_file.latest_version.update_attribute(:doi,'doi:10.1.1.1/xxx')

    get :show, params: { id: data_file }
    assert_response :success
    assert_select '#citation', text: /Bacall, F/, count:1
  end

  test 'resource count stats' do
    Factory(:data_file, policy: Factory(:public_policy))
    Factory(:data_file, policy: Factory(:private_policy))
    total = DataFile.count
    visible = DataFile.authorized_for('view').count
    assert_not_equal total, visible
    assert_not_equal 0, total
    assert_not_equal 0, visible
    get :index
    assert_response :success
    assert_equal total, assigns(:total_count)
    assert_equal visible, assigns(:visible_count)
  end

  test 'delete with data file with extracted samples' do
    login_as(Factory(:person))
    df = nil

    df = data_file_with_extracted_samples

    assert_no_difference('DataFile.count') do
      delete :destroy, params: { id: df.id }
    end
    assert_redirected_to destroy_samples_confirm_data_file_path(df)

    assert_difference('DataFile.count', -1) do
      assert_difference('Sample.count', -4) do
        delete :destroy, params: { id: df.id, destroy_extracted_samples: '1' }
      end
    end

    assert_redirected_to data_files_path

    df = data_file_with_extracted_samples

    assert_difference('DataFile.count', -1) do
      assert_no_difference('Sample.count') do
        delete :destroy, params: { id: df.id, destroy_extracted_samples: '0' }
      end
    end

    assert_redirected_to data_files_path
  end

  test 'extract samples confirmation' do
    login_as(Factory(:person))
    df = data_file_with_extracted_samples
    assert df.can_delete?
    get :destroy_samples_confirm, params: { id: df.id }
    assert_response :success
  end

  test 'extract samples confirmation not accessible if not can_delete?' do
    login_as(Factory(:person))
    df = data_file_with_extracted_samples(Factory(:person))
    refute df.can_delete?
    get :destroy_samples_confirm, params: { id: df.id }
    assert_redirected_to data_file_path(df)
    refute_nil flash[:error]
  end

  test 'cannot upload new version if samples have been extracted' do
    data_file = Factory(:data_file, contributor: User.current_user.person)
    Factory(:sample, originating_data_file: data_file, contributor: User.current_user.person)

    assert_no_difference('DataFile::Version.count') do
      post :create_version, params: { id: data_file.id, data_file: { title: nil }, content_blobs: [{ data: picture_file }], revision_comments: 'This is a new revision' }
    end

    assert_redirected_to data_file
    assert flash[:error].downcase.include?('samples')
  end

  test 'show openbis datafile' do
    mock_openbis_calls
    login_as(Factory(:person))
    df = openbis_linked_data_file

    get :show, params: { id: df.id }
    assert_response :success
    assert assigns(:data_file)
    assert_equal df, assigns(:data_file)
    assert_select 'div#openbis-details', count: 1
  end

  test 'show openbis datafile with rich metadata' do
    mock_openbis_calls
    login_as(Factory(:person))
    df = openbis_linked_data_file

    get :show, params: { id: df.id }
    assert_response :success
    assert assigns(:data_file)
    assert_equal df, assigns(:data_file)
    assert_select 'div#openbis-details-properties', count: 1
    assert_select 'div#openbis-details-properties label', text: 'SEEK_DATAFILE_ID:', count: 1
  end

  test "associated assays don't cause 500 error if create fails" do
    mock_http
    data_file, blob = valid_data_file_with_http_url
    data_file[:title] = ' ' # Will throw an error!
    assay = Factory(:assay, contributor: users(:datafile_owner).person)

    assert_no_difference('DataFile.count') do
      assert_no_difference('ContentBlob.count') do
        post :create, params: { data_file: data_file.merge(assay_assets_attributes: [{ assay_id: assay.id }]), content_blobs: [blob], policy_attributes: valid_sharing }

      end
    end

    assert assigns(:data_file).errors.any?
    assert_template :new
  end

  test 'should download jerm thing' do
    mock_http
    data_file = Factory(:jerm_data_file,
                        content_blob: Factory(:txt_content_blob, url: 'http://project.jerm/file.txt', data: 'jkl'),
                        policy: Factory(:public_policy))
    get :download, params: { id: data_file }
    assert_equal 'abc', @response.body
    assert_response :success
  end

  test 'should download jerm thing that throws 404 if a local copy is present' do
    mock_http
    data_file = Factory(:jerm_data_file,
                        content_blob: Factory(:txt_content_blob, url: 'http://mocked404.com', data: 'xyz'),
                        policy: Factory(:public_policy))
    get :download, params: { id: data_file }
    assert_equal 'xyz', @response.body
    assert_response :success
  end

  test 'should not download jerm thing that has gone if a local copy is present' do
    mock_http
    data_file = Factory(:jerm_data_file,
                        content_blob: Factory(:txt_content_blob, url: 'http://gone-project.jerm/file.txt', data: 'qwe'),
                        policy: Factory(:public_policy))
    get :download, params: { id: data_file }
    assert_equal 'qwe', @response.body
    assert_response :success
  end

  test 'should allow fetching of sample metadata for nels data' do
    setup_nels
    mock_http
    data_file = Factory(:data_file, policy: Factory(:public_policy), contributor: @user.person, assay_ids: [@assay.id],
                        content_blob: Factory(:url_content_blob, url: "https://test-fe.cbu.uib.no/nels/pages/sbi/sbi.xhtml?ref=#{@reference}"))

    refute data_file.content_blob.is_excel?
    refute data_file.content_blob.file_size

    assert_no_difference('Sample.count') do
      assert_enqueued_jobs(1, only: SampleDataExtractionJob) do
        assert_difference('Task.count') do
          VCR.use_cassette('nels/get_sample_metadata') do
            post :retrieve_nels_sample_metadata, params: { id: data_file }

            assert_redirected_to data_file
          end
        end
      end
    end

    assert assigns(:data_file).content_blob.is_excel?
    assert assigns(:data_file).content_blob.file_size > 0
  end

  test 'should gracefully handle case when sample metadata is unavailable when attempting to fetch' do
    setup_nels
    mock_http
    data_file = Factory(:data_file, policy: Factory(:public_policy), contributor: @user.person, assay_ids: [@assay.id],
                        content_blob: Factory(:url_content_blob, url: 'https://test-fe.cbu.uib.no/nels/pages/sbi/sbi.xhtml?ref=404'))

    refute data_file.content_blob.is_excel?
    refute data_file.content_blob.file_size

    assert_no_difference('Sample.count') do
      assert_no_enqueued_jobs(only: SampleDataExtractionJob) do
        VCR.use_cassette('nels/missing_sample_metadata') do
          post :retrieve_nels_sample_metadata, params: { id: data_file }

          assert_redirected_to data_file
          assert flash[:error].include?('No sample metadata')
        end
      end
    end

    refute assigns(:data_file).content_blob.is_excel?
  end

  test 'should re-authenticate with nels if oauth token expired when trying to fetch sample metadata' do
    setup_nels
    mock_http
    data_file = Factory(:data_file, policy: Factory(:public_policy), contributor: @user.person, assay_ids: [@assay.id],
                        content_blob: Factory(:url_content_blob, url: "https://test-fe.cbu.uib.no/nels/pages/sbi/sbi.xhtml?ref=#{@reference}"))

    @user.oauth_sessions.where(provider: 'NeLS').first.update_column(:expires_at, 1.day.ago)

    oauth_client = Nels::Oauth2::Client.new(Seek::Config.nels_client_id,
                                            Seek::Config.nels_client_secret,
                                            nels_oauth_callback_url,
                                            "data_file_id:#{data_file.id}")

    assert_no_difference('Sample.count') do
      assert_no_enqueued_jobs(only: SampleDataExtractionJob) do
        VCR.use_cassette('nels/get_sample_metadata') do
          post :retrieve_nels_sample_metadata, params: { id: data_file }

          assert_redirected_to oauth_client.authorize_url
        end
      end
    end
  end

  test 'should show nels links' do
    setup_nels
    mock_http
    nels_url = "https://test-fe.cbu.uib.no/nels/pages/sbi/sbi.xhtml?ref=#{@reference}"
    data_file = Factory(:data_file, policy: Factory(:public_policy), contributor: @user.person, assay_ids: [@assay.id],
                        content_blob: Factory(:url_content_blob, url: nels_url))

    get :show, params: { id: data_file }

    assert_response :success

    assert_select '.fileinfo b', text: /NeLS URL/
    assert_select '.fileinfo a[href=?]', nels_url
    assert_select '#buttons a.btn[href=?]', nels_url
  end

  test 'should unset policy sharing scope when updated' do
    refute_nil user=User.current_user
    df = Factory(:data_file, contributor: user.person)
    df.policy.update_column(:sharing_scope, Policy::ALL_USERS)

    assert_equal df.reload.policy.sharing_scope, Policy::ALL_USERS

    put :update, params: { id: df, data_file: { title: df.title }, policy_attributes: projects_policy(Policy::ACCESSIBLE, df.projects, Policy::EDITING) }

    assert_redirected_to data_file_path(df)
    assert_nil df.reload.policy.sharing_scope
  end

  test 'extract from data file and associate with assay' do
    person = Factory(:project_administrator)
    login_as(person)

    Factory(:string_sample_attribute_type, title: 'String')

    data_file = Factory(:data_file, content_blob: Factory(:sample_type_populated_template_content_blob),
                        policy: Factory(:private_policy), contributor: person)

    assay_asset1 = Factory(:assay_asset, asset: data_file, direction: AssayAsset::Direction::INCOMING,assay:Factory(:assay,contributor:person))
    assay_asset2 = Factory(:assay_asset, asset: data_file, direction: AssayAsset::Direction::OUTGOING,assay:Factory(:assay,contributor:person))

    sample_type = SampleType.new(title: 'from template', uploaded_template: true, project_ids: [person.projects.first.id], contributor: person)
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    sample_type.save!

    assert_difference('AssayAsset.count', 4) do
      assert_difference('Sample.count', 4) do
        post :extract_samples, params: { id: data_file.id, confirm: 'true', assay_ids: [assay_asset1.assay_id] }
      end
    end

    assigns(:samples).each do |sample|
      assert_equal [assay_asset1.assay], sample.assays
      assert_equal assay_asset1.direction, sample.assay_assets.first.direction
    end
  end

  test 'create content blob' do
    person = Factory(:person)
    login_as(person)
    blob = { data: picture_file }
    assert_difference('ContentBlob.count') do
      post :create_content_blob, params: { content_blobs: [blob] }
    end
    assert_response :success
    assert df = assigns(:data_file)
    refute_nil df.content_blob
    assert_equal df.content_blob.id, session[:uploaded_content_blob_id]
  end

  test 'create content blob with assay params' do
    # assay params may be passed when adding via the link from an existing assay
    person = Factory(:person)
    assay = Factory(:assay,contributor:person)
    login_as(person)
    blob = { data: picture_file }
    assert_difference('ContentBlob.count') do
      post :create_content_blob, params: {
          content_blobs: [blob],
          data_file: { assay_assets_attributes: [{ assay_id: assay.id.to_s }] }
      }
    end
    assert_response :success
    assert df = assigns(:data_file)
    assert_includes df.assay_assets.collect(&:assay), assay
  end

  test 'create content blob requires login' do
    logout
    blob = { data: picture_file }
    assert_no_difference('ContentBlob.count') do
      post :create_content_blob, params: { content_blobs: [blob] }
    end
    assert_response :redirect
  end

  test 'rightfield extraction extracts from template' do
    person = Factory(:person)
    login_as(person)
    content_blob = Factory(:rightfield_master_template_with_assay)

    session[:uploaded_content_blob_id] = content_blob.id.to_s

    post :rightfield_extraction_ajax, params: { content_blob_id: content_blob.id.to_s }, format: 'js'

    assert_response :success
    assert data_file = assigns(:data_file)
    assert assay = assigns(:assay)

    assert_equal 'My Title', data_file.title
    assert_equal 'My Description', data_file.description

    assert_equal 'My Assay Title', assay.title
    assert_equal 'My Assay Description', assay.description
    assert_equal 'http://jermontology.org/ontology/JERMOntology#Catabolic_response', assay.assay_type_uri
    assert_equal 'http://jermontology.org/ontology/JERMOntology#2-hybrid_system', assay.technology_type_uri

  end

  test 'rightfield extraction with assay params passed' do
    person = Factory(:person)
    assay = Factory(:assay, contributor:person)
    login_as(person)
    content_blob = Factory(:rightfield_master_template_with_assay)

    session[:uploaded_content_blob_id] = content_blob.id.to_s

    post :rightfield_extraction_ajax, params: {
        content_blob_id: content_blob.id.to_s,
        data_file: {assay_assets_attributes:[{assay_id:assay.id.to_s}]}
    }, format: 'js'

    assert_response :success
    assert data_file = assigns(:data_file)
    assert_equal [assay],data_file.assay_assets.collect(&:assay)
  end

  test 'create metadata' do
    person = Factory(:person)
    login_as(person)
    blob = Factory(:content_blob)
    session[:uploaded_content_blob_id] = blob.id
    project = person.projects.last
    params = { data_file: {
        title: 'Small File',
        project_ids: [project.id]
    }, tag_list:'fish, soup',
               policy_attributes: valid_sharing,
               content_blob_id: blob.id.to_s,
               assay_ids: [] }

    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_no_difference('Assay.count') do
          assert_no_difference('AssayAsset.count') do
            post :create_metadata, params: params
          end
        end
      end
    end

    assert (df = assigns(:data_file))

    assert_redirected_to df

    assert_equal [project], df.projects
    assert_equal blob, df.content_blob
    assert_equal 'Small File', df.title
    assert_equal person, df.contributor
    assert_empty df.assays
    assert_equal ['fish','soup'].sort,df.tags.sort

    al = ActivityLog.last
    assert_equal 'create', al.action
    assert_equal df, al.activity_loggable
    assert_equal person.user, al.culprit    

  end

  test 'create metadata with associated assay' do
    person = Factory(:person)
    login_as(person)
    assay = Factory(:assay, contributor: person)
    assert assay.can_edit?
    blob = Factory(:content_blob)
    session[:uploaded_content_blob_id] = blob.id
    project = person.projects.last
    params = {data_file: {
        title: 'Small File',
        project_ids: [project.id],
        assay_assets_attributes: [{ assay_id: assay.id }]
    }, policy_attributes: valid_sharing,
              content_blob_id: blob.id.to_s
    }

    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_no_difference('Assay.count') do
          assert_difference('AssayAsset.count') do
            post :create_metadata, params: params
          end
        end
      end
    end

    assert (df = assigns(:data_file))

    assert_redirected_to df

    assert_equal [assay], df.assays
  end

  test 'create metadata with associated assay ignores assay if not editable' do
    assay = Factory(:assay)
    person = Factory(:person)
    login_as(person)
    refute assay.can_edit?
    blob = Factory(:content_blob)
    session[:uploaded_content_blob_id] = blob.id
    project = person.projects.last
    params = {data_file: {
        title: 'Small File',
        project_ids: [project.id],
        assay_assets_attributes: [{ assay_id: assay.id }]
    }, policy_attributes: valid_sharing,
              content_blob_id: blob.id.to_s
    }

    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_no_difference('Assay.count') do
          assert_no_difference('AssayAsset.count') do
            post :create_metadata, params: params
          end
        end
      end
    end

    assert (df = assigns(:data_file))
    assert_empty df.assays
  end

  test 'create metadata fails if content blob not on session' do
    person = Factory(:person)
    login_as(person)

    blob = Factory(:content_blob)
    session.delete(:uploaded_content_blob_id)
    project = person.projects.last
    params = { data_file: {
        title: 'Small File',
        project_ids: [project.id]
    }, policy_attributes: valid_sharing,
               content_blob_id: blob.id.to_s }

    assert_no_difference('ActivityLog.count') do
      assert_no_difference('DataFile.count') do
        post :create_metadata, params: params
      end
    end

    assert_response :unprocessable_entity

    refute_empty (df = assigns(:data_file)).errors
    assert_equal ["The file uploaded doesn't match"], df.errors[:base]
  end

  test 'create metadata fails if content blob mismatched id on session' do
    person = Factory(:person)
    login_as(person)

    blob = Factory(:content_blob)
    session[:uploaded_content_blob_id] = Factory(:content_blob).id
    project = person.projects.last
    params = { data_file: {
        title: 'Small File',
        project_ids: [project.id]
    }, policy_attributes: valid_sharing,
               content_blob_id: blob.id.to_s }

    assert_no_difference('ActivityLog.count') do
      assert_no_difference('DataFile.count') do
        post :create_metadata, params: params
      end
    end

    assert_response :unprocessable_entity

    refute_empty (df = assigns(:data_file)).errors
    assert_equal ["The file uploaded doesn't match"], df.errors[:base]
  end

  test 'create metadata with validation failure' do
    person = Factory(:person)
    login_as(person)
    blob = Factory(:content_blob)
    session[:uploaded_content_blob_id] = blob.id
    project = person.projects.last
    params = { data_file: {
        project_ids: [project.id]
    }, policy_attributes: valid_sharing,
               content_blob_id: blob.id }

    assert_no_difference('ActivityLog.count') do
      assert_no_difference('DataFile.count') do
        post :create_metadata, params: params
      end
    end

    assert_response :unprocessable_entity

    assert (df = assigns(:data_file))
    assert_equal [project], df.projects
    assert_equal blob, df.content_blob
    assert_nil df.title
    refute_empty df.errors
  end

  test 'create metadata requires login' do
    logout
    blob = Factory(:content_blob)
    session[:uploaded_content_blob_id] = blob.id
    project = Factory(:project)
    params = { data_file: {
        project_ids: [project.id]
    }, policy_attributes: valid_sharing,
               content_blob_id: blob.id }

    assert_no_difference('ActivityLog.count') do
      assert_no_difference('DataFile.count') do
        post :create_metadata, params: params
      end
    end

    assert_response :redirect

  end

  test 'create metadata filters projects' do
    # won't associate to projects the current_user isn't a member of
    person = Factory(:person)
    login_as(person)
    blob = Factory(:content_blob)
    session[:uploaded_content_blob_id] = blob.id
    project = Factory(:project)
    refute_includes person.projects, project
    params = { data_file: {
        title: 'Small File',
        project_ids: [project.id]
    }, policy_attributes: valid_sharing,
               content_blob_id: blob.id }

    assert_no_difference('ActivityLog.count') do
      assert_no_difference('DataFile.count') do
        post :create_metadata, params: params
      end
    end

    assert_response :unprocessable_entity

    assert (df = assigns(:data_file))
    assert_empty df.projects
  end

  test 'create metadata together with new assay' do
    person = Factory(:person)
    login_as(person)

    blob = Factory(:content_blob)
    session[:uploaded_content_blob_id] = blob.id

    project = person.projects.last
    assay_class = AssayClass.experimental
    study = Factory(:study,investigation:Factory(:investigation,contributor:person), contributor:person)
    assert study.can_edit?
    sop = Factory(:sop, projects: [project], contributor: person)
    assert sop.can_view?

    params = { data_file: {
        title: 'Small File',
        project_ids: [project.id]
    }, assay: {
        create_assay: true,
        assay_class_id: assay_class.id,
        title: 'my wonderful assay',
        description: 'assay description',
        study_id: study.id,
        sop_id: sop.id,
        assay_type_uri: 'http://jermontology.org/ontology/JERMOntology#Catabolic_response',
        technology_type_uri: 'http://jermontology.org/ontology/JERMOntology#Binding'
    },
               policy_attributes: valid_sharing,
               content_blob_id: blob.id.to_s }

    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_difference('Assay.count') do
          assert_difference('AssayAsset.count', 2) do
            post :create_metadata, params: params
          end
        end
      end
    end

    assert (df = assigns(:data_file))
    assert_equal 1, df.assays.count
    assay = df.assays.first
    assert_equal 'my wonderful assay', assay.title
    assert_equal 'assay description', assay.description
    assert_equal study, assay.study
    assert assay.assay_class.is_experimental?
    assert_equal [project], assay.projects
    assert_equal 'http://jermontology.org/ontology/JERMOntology#Catabolic_response', assay.assay_type_uri
    assert_equal 'http://jermontology.org/ontology/JERMOntology#Binding', assay.technology_type_uri
    assert_equal [sop], assay.sops
  end

  test 'new assay adopts datafile policy' do
    person = Factory(:person)
    manager = Factory(:person)
    other_project = Factory(:project)
    login_as(person)

    blob = Factory(:content_blob)
    session[:uploaded_content_blob_id] = blob.id

    project = person.projects.last
    assay_class = AssayClass.experimental
    investigation = Factory(:investigation,projects:[project], contributor:person)
    study = Factory(:study,investigation:investigation, contributor:person)
    assert study.can_edit?

    sharing = {
        access_type: Policy::PRIVATE,
        permissions_attributes: {
            '0' => {
                contributor_type: 'Person',
                contributor_id: manager.id,
                access_type: Policy::MANAGING
            },
            '1' => {
                contributor_type: 'Project',
                contributor_id: other_project.id,
                access_type: Policy::VISIBLE
            }
        }
    }

    params = { data_file: {
        title: 'Small File',
        project_ids: [project.id]
    }, assay: {
        create_assay: true,
        assay_class_id: assay_class.id,
        title: 'my wonderful assay',
        description: 'assay description',
        study_id: study.id,
        sop_id: nil,
        assay_type_uri: 'http://jermontology.org/ontology/JERMOntology#Catabolic_response',
        technology_type_uri: 'http://jermontology.org/ontology/JERMOntology#Binding'
    },
               policy_attributes: sharing,
               content_blob_id: blob.id.to_s }

    assert_difference('ActivityLog.count') do
      assert_difference('DataFile.count') do
        assert_difference('Assay.count') do
          assert_difference('Policy.count', 2) do
            assert_difference('Permission.count', 4) do
              post :create_metadata, params: params
            end
          end
        end
      end
    end

    assert (df = assigns(:data_file))
    assert_equal Policy::PRIVATE, df.policy.access_type
    assert_equal 2, df.policy.permissions.count
    assert_equal manager, df.policy.permissions[0].contributor
    assert_equal Policy::MANAGING, df.policy.permissions[0].access_type
    assert_equal other_project, df.policy.permissions[1].contributor
    assert_equal Policy::VISIBLE, df.policy.permissions[1].access_type

    assay = df.assays.first
    refute_equal df.policy.id, assay.policy.id
    assert_equal Policy::PRIVATE, assay.policy.access_type
    assert_equal 2, assay.policy.permissions.count
    assert_equal manager, assay.policy.permissions[0].contributor
    assert_equal Policy::MANAGING, assay.policy.permissions[0].access_type
    assert_equal other_project, assay.policy.permissions[1].contributor
    assert_equal Policy::VISIBLE, assay.policy.permissions[1].access_type
  end

  test 'create metadata with new assay fails if study not editable' do
    person = Factory(:person)
    project = person.projects.last
    another_person = Factory(:person,project:project)
    investigation = Factory(:investigation,projects:[project],contributor:another_person)
    study = Factory(:study, contributor:another_person,investigation:investigation)

    login_as(person)

    blob = Factory(:content_blob)
    session[:uploaded_content_blob_id] = blob.id

    assay_class = AssayClass.experimental
    refute study.can_edit?

    params = { data_file: {
        title: 'Small File',
        project_ids: [project.id]
    }, assay: {
        create_assay: true,
        assay_class_id: assay_class.id,
        title: 'my wonderful assay',
        description: 'assay description',
        study_id: study.id,
        assay_type_uri: 'http://jermontology.org/ontology/JERMOntology#Catabolic_response',
        technology_type_uri: 'http://jermontology.org/ontology/JERMOntology#Binding'
    },
               policy_attributes: valid_sharing,
               content_blob_id: blob.id.to_s }

    assert_no_difference('ActivityLog.count') do
      assert_no_difference('DataFile.count') do
        assert_no_difference('Assay.count') do
          assert_no_difference('AssayAsset.count') do
            post :create_metadata, params: params
          end
        end
      end
    end

    assert_response :unprocessable_entity
  end

  test 'when updating, assay linked to must be editable' do
    person = Factory(:person)
    login_as(person)
    data_file = Factory(:data_file,contributor:person,projects:person.projects)
    assert data_file.can_edit?
    another_person = Factory(:person)
    another_person.add_to_project_and_institution(person.projects.first,person.institutions.first)
    another_person.save!

    investigation = Factory(:investigation,contributor:person,projects:person.projects)

    study = Factory(:study, contributor:person, investigation:investigation)

    good_assay = Factory(:assay,study_id:study.id,contributor:another_person,policy:Factory(:editing_public_policy))
    bad_assay = Factory(:assay,study_id:study.id,contributor:another_person,policy:Factory(:publicly_viewable_policy))

    assert good_assay.can_edit?
    refute bad_assay.can_edit?

    assert_no_difference('AssayAsset.count') do
      put :update, params: { id: data_file.id, data_file: { title: data_file.title, assay_assets_attributes: [{ assay_id: bad_assay.id }] } }
    end
    # FIXME: currently just skips the bad assay, but ideally should respond with an error status
    #assert_response :unprocessable_entity
    #
    data_file.reload
    assert_empty data_file.assays

    assert_difference('AssayAsset.count') do
      put :update, params: { id: data_file.id, data_file: { title: data_file.title, assay_assets_attributes: [{ assay_id: good_assay.id }] } }
    end
    data_file.reload
    assert_equal [good_assay], data_file.assays

  end

  test 'when creating, assay linked to must be editable' do
    person = Factory(:person)
    login_as(person)

    another_person = Factory(:person)
    another_person.add_to_project_and_institution(person.projects.first,person.institutions.first)
    another_person.save!

    investigation = Factory(:investigation,contributor:person,projects:person.projects)

    study = Factory(:study, contributor:person, investigation:investigation)

    good_assay = Factory(:assay,study_id:study.id,contributor:another_person,policy:Factory(:editing_public_policy))
    bad_assay = Factory(:assay,study_id:study.id,contributor:another_person,policy:Factory(:publicly_viewable_policy))

    assert good_assay.can_edit?
    refute bad_assay.can_edit?

    data_file, blob = valid_data_file

    assert_no_difference('AssayAsset.count') do
      post :create, params: { data_file: data_file.merge(assay_assets_attributes: [{ assay_id: bad_assay.id }]), content_blobs: [blob], policy_attributes: valid_sharing }
    end

    # FIXME: currently just skips the bad assay, but ideally should respond with an error status
    assert_empty assigns(:data_file).assays
    #assert_response :unprocessable_entity

    data_file, blob = valid_data_file

    assert_difference('AssayAsset.count') do
      post :create, params: { data_file: data_file.merge(assay_assets_attributes: [{ assay_id: good_assay.id }]), content_blobs: [blob], policy_attributes: valid_sharing }
    end
    data_file = assigns(:data_file)
    assert_equal [good_assay],data_file.assays
  end

  test 'create assay should be checked with new assay containing title' do
    df = Factory.build(:data_file, content_blob:Factory(:txt_content_blob))
    refute_nil df.content_blob

    # creating a new assay should be selected if an unsaved assay if present, with a populated title
    assay_to_be_created = Factory.build(:assay,title:'new assay')
    session[:processed_datafile]=df
    session[:processed_assay]=assay_to_be_created

    get :provide_metadata

    assert_response :success
    refute_nil assigns(:create_new_assay)
    assert assigns(:create_new_assay)
    assert_select "input#assay_create_assay[checked=checked]", count:1

  end

  test 'create assay should not be checked with not title' do
    df = Factory.build(:data_file, content_blob:Factory(:txt_content_blob))

    # creating a new assay should be selected if an unsaved assay if present, with a populated title
    assay_no_title = Factory.build(:assay,title:'')
    session[:processed_datafile]=df

    assert assay_no_title.title.blank?
    session[:processed_assay]=assay_no_title
    get :provide_metadata

    assert_response :success
    refute_nil assigns(:create_new_assay)
    refute assigns(:create_new_assay)
    assert_select "input#assay_create_assay[checked=checked]", count:0
  end

  test 'create assay should not be checked with existing assay' do
    df = Factory.build(:data_file, content_blob:Factory(:txt_content_blob))

    # creating a new assay should be selected if an unsaved assay if present, with a populated title
    existing_assay = Factory(:assay)
    session[:processed_datafile]=df

    session[:processed_assay]=existing_assay
    get :provide_metadata

    assert_response :success
    refute_nil assigns(:create_new_assay)
    refute assigns(:create_new_assay)
    assert_select "input#assay_create_assay[checked=checked]", count:0
  end

  test 'should not select non editable assay ids when passed to provide metadata' do
    assay1 = Factory(:assay, contributor:User.current_user.person)
    assay2 = Factory(:assay, contributor:User.current_user.person)
    assay3 = Factory(:assay, contributor:Factory(:person))

    assert assay1.can_edit?
    assert assay2.can_edit?
    refute assay3.can_edit?

    register_content_blob(skip_provide_metadata:true)

    get :provide_metadata, params: { assay_ids:[assay3.id] }
    assert_response :success

    #assay 3 is not allowed
    assert df=assigns(:data_file)
    refute_includes df.assay_assets.collect(&:assay),assay1
    refute_includes df.assay_assets.collect(&:assay),assay2
    refute_includes df.assay_assets.collect(&:assay),assay3
  end

  def edit_max_object(df)
    add_tags_to_test_object(df)
    add_creator_to_test_object(df)
  end

  private

  def data_file_with_extracted_samples(contributor = User.current_user.person)
    data_file = Factory :data_file, content_blob: Factory(:sample_type_populated_template_content_blob),
                        policy: Factory(:private_policy), contributor: contributor
    sample_type = SampleType.new title: 'from template', projects: contributor.projects, contributor:contributor
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    create_sample_attribute_type
    sample_type.build_attributes_from_template
    disable_authorization_checks { sample_type.save! }

    assert_difference('Sample.count', 4) do
      data_file.extract_samples(sample_type, true)
      disable_authorization_checks { data_file.save! }
    end

    data_file.reload

    assert_equal 4, data_file.extracted_samples.count

    data_file
  end

  def mock_http
    stub_request(:get, 'http://mockedlocation.com/a-piccy.png').to_return(body: File.new("#{Rails.root}/test/fixtures/files/file_picture.png"), status: 200, headers: { 'Content-Type' => 'image/png' })
    stub_request(:head, 'http://mockedlocation.com/a-piccy.png').to_return(status: 200, headers: { 'Content-Type' => 'image/png' })

    stub_request(:get, 'http://mockedlocation.com/txt_test.txt').to_return(body: File.new("#{Rails.root}/test/fixtures/files/txt_test.txt"), status: 200, headers: { 'Content-Type' => 'text/plain; charset=UTF-8' })
    stub_request(:head, 'http://mockedlocation.com/txt_test.txt').to_return(status: 200, headers: { content_type: 'text/plain; charset=UTF-8' })

    stub_request(:head, 'http://redirectlocation.com').to_return(status: 200, headers: { content_type: 'text/html' })
    stub_request(:get, 'http://redirectlocation.com').to_return(body: '<html><head></head><body></body></html>', status: 200, headers: { content_type: 'text/html' })

    stub_request(:any, 'http://mocked301.com').to_return(status: 301, headers: { location: 'http://redirectlocation.com' })
    stub_request(:any, 'http://mockedbad301.com').to_return(status: 301, headers: { location: 'http://mocked404.com' })
    stub_request(:any, 'http://mocked302.com').to_return(status: 302, headers: { location: 'http://redirectlocation.com' })
    stub_request(:any, 'http://mocked401.com/file.txt').to_return(status: 401)
    stub_request(:any, 'http://mocked403.com/file.txt').to_return(status: 403)
    stub_request(:any, 'http://mocked404.com').to_return(status: 404)

    stub_request(:get, 'http://mockedlocation.com/small.txt').to_return(body: 'bananafish' * 10, status: 200, headers: { content_type: 'text/plain; charset=UTF-8', content_length: 100 })
    stub_request(:head, 'http://mockedlocation.com/small.txt').to_return(status: 200, headers: { content_type: 'text/plain; charset=UTF-8', content_length: 100 })

    stub_request(:get, 'http://mockedlocation.com/big.txt').to_return(body: 'bananafish' * 500, status: 200, headers: { content_type: 'text/plain; charset=UTF-8', content_length: 5000 })
    stub_request(:head, 'http://mockedlocation.com/big.txt').to_return(status: 200, headers: { content_type: 'text/plain; charset=UTF-8', content_length: 5000 })

    stub_request(:get, 'http://mockedlocation.com').to_return(body: '<!doctype html><html><head></head><body>internet.</body></html>', status: 200,
                                                              headers: { content_type: 'text/html; charset=UTF-8', content_length: 63 })
    stub_request(:head, 'http://mockedlocation.com').to_return(status: 200, headers: { content_type: 'text/html; charset=UTF-8', content_length: 63 })

    stub_request(:get, 'http://mockedlocation.com/nohead.txt').to_return(body: 'bananafish' * 500, status: 200, headers: { content_type: 'text/plain; charset=UTF-8', content_length: 5000 })
    stub_request(:head, 'http://mockedlocation.com/nohead.txt').to_return(status: 405)

    stub_request(:get, 'http://project.jerm/file.txt').to_return(body: 'abc', status: 200, headers: { 'Content-Type' => 'text/plain; charset=UTF-8' })
    stub_request(:head, 'http://project.jerm/file.txt').to_return(status: 200, headers: { content_type: 'text/plain; charset=UTF-8' })

    stub_request(:get, 'http://gone-project.jerm/file.txt').to_raise(SocketError)
    stub_request(:head, 'http://gone-project.jerm/file.txt').to_raise(SocketError)
  end

  def mock_https
    file = "#{Rails.root}/test/fixtures/files/txt_test.txt"
    stub_request(:get, 'https://mockedlocation.com/txt_test.txt').to_return(body: File.new(file), status: 200, headers: { 'Content-Type' => 'text/plain; charset=UTF-8' })
    stub_request(:head, 'https://mockedlocation.com/txt_test.txt').to_return(status: 200, headers: { content_type: 'text/plain; charset=UTF-8' })

    stub_request(:head, 'https://redirectlocation.com').to_return(status: 200, headers: { content_type: 'text/html' })

    stub_request(:any, 'https://mocked301.com').to_return(status: 301, headers: { location: 'https://redirectlocation.com' })
    stub_request(:any, 'https://mocked302.com').to_return(status: 302, headers: { location: 'https://redirectlocation.com' })
    stub_request(:any, 'https://mocked401.com').to_return(status: 401)
    stub_request(:any, 'https://mocked404.com').to_return(status: 404)
  end

  def picture_file
    fixture_file_upload('files/file_picture.png', 'image/png')
  end

  def valid_data_file
    [{ title: 'Test',simulation_data:'0', project_ids: [User.current_user.person.projects.first.id]}, { data: picture_file }]
  end

  def valid_data_file_with_http_url
    [{ title: 'Test HTTP', project_ids: [projects(:sysmo_project).id] }, { data_url: 'http://mockedlocation.com/txt_test.txt', make_local_copy: '0' }]
  end

  def valid_data_file_with_https_url
    [{ title: 'Test HTTP', project_ids: [projects(:sysmo_project).id] }, { data_url: 'https://mockedlocation.com/txt_test.txt', make_local_copy: '0' }]
  end

  test 'policy visibility in JSON' do
    asset_housekeeper = Factory(:asset_housekeeper)
    private_policy = Factory(:private_policy)
    visible_policy = Factory(:publicly_viewable_policy)
    owner = Factory(:person)
    random_person = Factory(:person)
    private_item = Factory(:data_file,
                           policy: private_policy,
                           title: 'some title',
                           description: 'some description',
                           contributor: owner)
    visible_item = Factory(:data_file,
                           policy: visible_policy,
                           title: 'some title',
                           description: 'some description',
                           contributor: owner)

    login_as owner.user

    get :show, params: { id: private_item, format: :json }
    assert_response :success
    parsed_response = JSON.parse(@response.body)
    assert parsed_response['data']['attributes'].key?('policy')
    assert parsed_response['data']['attributes']['policy'].key?('access')

    get :show, params: { id: visible_item, format: :json }
    assert_response :success
    parsed_response = JSON.parse(@response.body)
    assert parsed_response['data']['attributes'].key?('policy')
    assert parsed_response['data']['attributes']['policy'].key?('access')

    logout

    get :show, params: { id: private_item, format: :json }
    assert_response :forbidden
    get :show, params: { id: visible_item, format: :json }
    assert_response :success
    parsed_response = JSON.parse(@response.body)
    assert_not parsed_response['data']['attributes'].key?('policy')

    login_as random_person.user
    get :show, params: { id: private_item, format: :json }
    assert_response :forbidden
    get :show, params: { id: visible_item, format: :json }
    assert_response :success
    parsed_response = JSON.parse(@response.body)
    assert_not parsed_response['data']['attributes'].key?('policy')
    logout
  end

  test 'should show view content button for image' do
    data_file = Factory(:data_file, content_blob: Factory(:image_content_blob))
    login_as(data_file.contributor)

    get :show, params: { id: data_file }

    assert_response :success
    assert_select 'a.btn[data-lightbox]', count: 1
  end

  # registers a new content blob, and triggers the javascript 'rightfield_extraction_ajax' call, and results in the metadata form HTML in the response
  # this replicates the old behaviour and result of calling #new
  def register_content_blob(skip_provide_metadata:false)

    blob = {data: picture_file}
    assert_difference('ContentBlob.count') do
      post :create_content_blob, params: { content_blobs: [blob] }
    end
    content_blob_id = assigns(:data_file).content_blob.id
    session[:uploaded_content_blob_id] = content_blob_id.to_s
    post :rightfield_extraction_ajax, params: { content_blob_id:content_blob_id.to_s, format:'js' }
    get :provide_metadata unless skip_provide_metadata
  end

  test 'manage menu item appears according to permission' do
    check_manage_edit_menu_for_type('data_file')
  end

  test 'can access manage page with manage rights' do
    person = Factory(:person)
    data_file = Factory(:data_file, contributor:person)
    login_as(person)
    assert data_file.can_manage?
    get :manage, params: {id: data_file}
    assert_response :success

    # check the project form exists, studies and assays don't have this
    assert_select 'div#add_projects_form', count:1

    # check sharing form exists
    assert_select 'div#sharing_form', count:1

    # should be a temporary sharing link
    assert_select 'div#temporary_links', count:1

    assert_select 'div#author-form', count:1
  end

  test 'cannot access manage page with edit rights' do
    person = Factory(:person)
    data_file = Factory(:data_file, policy:Factory(:private_policy, permissions:[Factory(:permission, contributor:person, access_type:Policy::EDITING)]))
    login_as(person)
    assert data_file.can_edit?
    refute data_file.can_manage?
    get :manage, params: {id:data_file}
    assert_redirected_to data_file
    refute_nil flash[:error]
  end

  test 'manage_update' do
    proj1=Factory(:project)
    proj2=Factory(:project)
    person = Factory(:person,project:proj1)
    other_person = Factory(:person)
    person.add_to_project_and_institution(proj2,person.institutions.first)
    person.save!
    other_creator = Factory(:person,project:proj1)
    other_creator.add_to_project_and_institution(proj2,other_creator.institutions.first)
    other_creator.save!

    data_file = Factory(:data_file, contributor:person, projects:[proj1], policy:Factory(:private_policy))

    login_as(person)
    assert data_file.can_manage?

    patch :manage_update, params: {id: data_file,
                                   data_file: {
                                       creator_ids: [other_creator.id],
                                       project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    assert_redirected_to data_file

    data_file.reload
    assert_equal [proj1,proj2],data_file.projects.sort_by(&:id)
    assert_equal [other_creator],data_file.creators
    assert_equal Policy::VISIBLE,data_file.policy.access_type
    assert_equal 1,data_file.policy.permissions.count
    assert_equal other_person,data_file.policy.permissions.first.contributor
    assert_equal Policy::MANAGING,data_file.policy.permissions.first.access_type

    assert_equal 'Data file was successfully updated.',flash[:notice]

  end

  test 'manage_update fails without manage rights' do
    proj1=Factory(:project)
    proj2=Factory(:project)
    person = Factory(:person, project:proj1)
    person.add_to_project_and_institution(proj2,person.institutions.first)
    person.save!

    other_person = Factory(:person)

    other_creator = Factory(:person,project:proj1)
    other_creator.add_to_project_and_institution(proj2,other_creator.institutions.first)
    other_creator.save!

    data_file = Factory(:data_file, projects:[proj1], policy:Factory(:private_policy,
                                                                     permissions:[Factory(:permission,contributor:person, access_type:Policy::EDITING)]))

    login_as(person)
    refute data_file.can_manage?
    assert data_file.can_edit?

    assert_equal [proj1],data_file.projects
    assert_empty data_file.creators

    patch :manage_update, params: {id: data_file,
                                   data_file: {
                                       creator_ids: [other_creator.id],
                                       project_ids: [proj1.id, proj2.id]
                                   },
                                   policy_attributes: {access_type: Policy::VISIBLE, permissions_attributes: {'1' => {contributor_type: 'Person', contributor_id: other_person.id, access_type: Policy::MANAGING}}
                                   }}

    refute_nil flash[:error]

    data_file.reload
    assert_equal [proj1],data_file.projects
    assert_empty data_file.creators
    assert_equal Policy::PRIVATE,data_file.policy.access_type
    assert_equal 1,data_file.policy.permissions.count
    assert_equal person,data_file.policy.permissions.first.contributor
    assert_equal Policy::EDITING,data_file.policy.permissions.first.access_type

  end

  test 'should create with discussion link' do
    person = Factory(:person)
    login_as(person)
    blob = Factory(:content_blob)
    session[:uploaded_content_blob_id] = blob.id
    data_file =  {title: 'DataFile', project_ids: [person.projects.first.id], discussion_links_attributes:[{url: "http://www.slack.com/"}]}
    assert_difference('AssetLink.discussion.count') do
      assert_difference('DataFile.count') do
        post :create_metadata, params: {data_file: data_file, content_blob_id: blob.id.to_s, policy_attributes: { access_type: Policy::VISIBLE }}
      end
    end
    data_file = assigns(:data_file)
    assert_redirected_to data_file_path(data_file)
    assert_equal 'http://www.slack.com/', data_file.discussion_links.first.url
    assert_equal AssetLink::DISCUSSION, data_file.discussion_links.first.link_type
  end


  test 'should show discussion link' do
    asset_link = Factory(:discussion_link)
    data_file = Factory(:data_file, discussion_links: [asset_link], policy: Factory(:public_policy, access_type: Policy::VISIBLE))
    get :show, params: { id: data_file }
    assert_response :success
    assert_select 'div.panel-heading', text: /Discussion Channel/, count: 1
  end

  test 'should update data_file with discussion link' do
    person = Factory(:person)
    data_file = Factory(:data_file, contributor: person)
    login_as(person)
    assert_nil data_file.discussion_links.first
    assert_difference('AssetLink.discussion.count') do
      assert_difference('ActivityLog.count') do
        put :update, params: { id: data_file.id, data_file: { discussion_links_attributes:[{url: "http://www.slack.com/"}] } }
      end
    end
    assert_redirected_to data_file_path(assigns(:data_file))
    assert_equal 'http://www.slack.com/', data_file.discussion_links.first.url
  end

  test 'should update model with edited discussion link' do
    person = Factory(:person)
    data_file = Factory(:data_file, contributor: person, discussion_links:[Factory(:discussion_link)])
    login_as(person)
    assert_equal 1,data_file.discussion_links.count
    assert_no_difference('AssetLink.discussion.count') do
      assert_difference('ActivityLog.count') do
        put :update, params: { id: data_file.id, data_file: { discussion_links_attributes:[{id:data_file.discussion_links.first.id, url: "http://www.wibble.com/"}] } }
      end
    end
    data_file = assigns(:data_file)
    assert_redirected_to data_file_path(data_file)
    assert_equal 1,data_file.discussion_links.count
    assert_equal 'http://www.wibble.com/', data_file.discussion_links.first.url
  end

  test 'should destroy related assetlink when the discussion link is removed ' do
    person = Factory(:person)
    login_as(person)
    asset_link = Factory(:discussion_link)
    data_file = Factory(:data_file, discussion_links: [asset_link], policy: Factory(:public_policy, access_type: Policy::VISIBLE), contributor: person)
    assert_difference('AssetLink.discussion.count', -1) do
      put :update, params: { id: data_file.id, data_file: { discussion_links_attributes:[{id:asset_link.id, _destroy:'1'}] } }
    end
    assert_redirected_to data_file_path(data_file = assigns(:data_file))
    assert_empty data_file.discussion_links
  end

end
