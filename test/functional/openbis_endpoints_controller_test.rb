require 'test_helper'
require 'openbis_test_helper'

include SharingFormTestHelper

class OpenbisEndpointsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  def setup
    mock_openbis_calls
    Factory(:person)
    @project_administrator = Factory(:project_administrator)
    @project = @project_administrator.projects.first
  end

  test 'show' do
    ep = Factory(:openbis_endpoint, project: @project)
    login_as(@project_administrator)

    get :show, id: ep.id
    assert_response :success

  end

  test 'destroy' do
    ep = Factory(:openbis_endpoint, project: @project)
    login_as(@project_administrator)
    assert ep.can_delete?

    assert_difference('OpenbisEndpoint.count', -1) do
      delete :destroy, id: ep.id, project_id: @project.id
      assert_redirected_to project_openbis_endpoints_path(@project)
    end

    person = Factory(:person)
    project = person.projects.first
    ep = Factory(:openbis_endpoint, project: project)
    login_as(person)
    refute ep.can_delete?

    assert_no_difference('OpenbisEndpoint.count') do
      delete :destroy, id: ep.id, project_id: project.id
      assert_redirected_to :root
      refute_nil flash[:error]
    end

    # other scenerios are covered in the unit tests for can_delete?
  end

  test 'create' do
    login_as(@project_administrator)

    policy_attributes = { access_type: Policy::ACCESSIBLE,
                          permissions_attributes: project_permissions([@project], Policy::ACCESSIBLE) }

    assert_difference('OpenbisEndpoint.count') do
      assert_difference('Delayed::Job.count', 2) do
        post :create, project_id: @project.id, openbis_endpoint:
            {
                as_endpoint: 'http://as.com',
                dss_endpoint: 'http://dss.com',
                web_endpoint: 'http://web.com',
                username: 'fred',
                password: 'secret',
                refresh_period_mins: '123',
                space_perm_id: 'space-id',
                study_types: 'ST1, ST2',
                assay_types: 'ASSAY, DEFAULT'
            },
             policy_attributes: policy_attributes
      end
    end
    assert assigns(:openbis_endpoint)
    ep = assigns(:openbis_endpoint)
    assert_equal 'http://as.com', ep.as_endpoint
    assert_equal 'http://dss.com', ep.dss_endpoint
    assert_equal 'http://web.com', ep.web_endpoint
    assert_equal 'fred', ep.username
    assert_equal 'secret', ep.password
    assert_equal 123, ep.refresh_period_mins
    assert_equal 'space-id', ep.space_perm_id

    assert_equal Policy::ACCESSIBLE, ep.policy.access_type
    assert_equal 1, ep.policy.permissions.count

    ep.policy.permissions.each do |permission|
      assert_equal permission.contributor_type, 'Project'
      assert_equal @project.id, (permission.contributor_id)
      assert_equal permission.policy_id, ep.policy_id
      assert_equal permission.access_type, Policy::ACCESSIBLE
    end

    assert_equal ['ST1', 'ST2'], ep.study_types
    assert_equal ['ASSAY', 'DEFAULT'], ep.assay_types

  end

  test 'update' do
    login_as(@project_administrator)
    ep = Factory(:openbis_endpoint, project: @project)
    refute_equal Policy::ACCESSIBLE, ep.policy.access_type
    assert_empty ep.policy.permissions

    policy_attributes = { access_type: Policy::ACCESSIBLE,
                          permissions_attributes: project_permissions([@project], Policy::ACCESSIBLE) }

    put :update, id: ep.id, project_id: @project.id, openbis_endpoint:
        {
            as_endpoint: 'http://as.com',
            dss_endpoint: 'http://dss.com',
            web_endpoint: 'http://web.com',
            username: 'fred',
            password: 'secret',
            refresh_period_mins: '123',
            space_perm_id: 'space-id',
            study_types: 'ST, ST2',
            assay_types: 'ASSAY, ASS'
        },
        policy_attributes: policy_attributes

    assert assigns(:openbis_endpoint)
    ep = assigns(:openbis_endpoint)
    assert_equal 'http://as.com', ep.as_endpoint
    assert_equal 'http://dss.com', ep.dss_endpoint
    assert_equal 'http://web.com', ep.web_endpoint
    assert_equal 'fred', ep.username
    assert_equal 'secret', ep.password
    assert_equal 123, ep.refresh_period_mins
    assert_equal 'space-id', ep.space_perm_id

    assert_equal Policy::ACCESSIBLE, ep.policy.access_type
    assert_equal 1, ep.policy.permissions.count

    ep.policy.permissions.each do |permission|
      assert_equal permission.contributor_type, 'Project'
      assert_equal @project.id, (permission.contributor_id)
      assert_equal permission.policy_id, ep.policy_id
      assert_equal permission.access_type, Policy::ACCESSIBLE
    end

    assert_equal ['ST', 'ST2'], ep.study_types
    assert_equal ['ASSAY', 'ASS'], ep.assay_types

  end

# TZ adding is handled by datasets_controller
=begin
  test 'add dataset' do
    disable_authorization_checks do
      @project.update_attributes(default_license: 'wibble')
    end
    endpoint = Factory(:openbis_endpoint, project: @project, policy: Factory(:private_policy, permissions: [Factory(:permission, contributor: @project)]))
    perm_id = '20160210130454955-23'
    login_as(@project_administrator)
    assert_difference('DataFile.count') do
      assert_difference('ActivityLog.count') do
        post :add_dataset, id: endpoint.id, project_id: @project.id, dataset_perm_id: perm_id
        assert_nil flash[:error]
      end
    end
    data_file = assigns(:data_file)
    data_file = DataFile.find(data_file.id)
    assert_redirected_to data_file
    assert_equal '20160210130454955-23', data_file.content_blob.openbis_dataset.perm_id
    assert_equal 'wibble', data_file.license

    refute_equal data_file.policy, endpoint.policy
    assert_equal endpoint.policy.access_type, data_file.policy.access_type
    assert_equal 1, data_file.policy.permissions.length
    permission = data_file.policy.permissions.first
    assert_equal @project, permission.contributor
    assert_equal Policy::NO_ACCESS, permission.access_type

    log = ActivityLog.last
    assert_equal 'create', log.action
    assert_equal data_file, log.activity_loggable
    assert_equal @project_administrator.user, log.culprit
    assert_equal endpoint, log.referenced
  end


  test 'add dataset permissions' do
    # already tests for project admin in test add dataset

    # project member
    person = Factory(:person)
    project = person.projects.first
    endpoint = Factory(:openbis_endpoint, project: project)
    perm_id = '20160210130454955-23'
    login_as(person)
    assert_difference('DataFile.count') do
      post :add_dataset, id: endpoint.id, project_id: project.id, dataset_perm_id: perm_id
      assert_nil flash[:error]
    end

    logout

    # none project member
    person = Factory(:person)
    endpoint = Factory(:openbis_endpoint, project: Factory(:project))
    perm_id = '20160210130454955-23'
    login_as(person)
    assert_no_difference('DataFile.count') do
      post :add_dataset, id: endpoint.id, project_id: project.id, dataset_perm_id: perm_id
      refute_nil flash[:error]
    end
  end
=end

  test 'browse' do
    # project admin can browse
    login_as(@project_administrator)
    get :browse, project_id: @project.id
    assert_response :success

    logout

    # project member can browse
    person = Factory(:person)
    project = person.projects.first
    login_as(person)
    get :browse, project_id: project.id
    assert_response :success

    logout

    # non project member cannot browse
    person = Factory(:person)
    login_as(person)
    get :browse, project_id: Factory(:project).id
    assert_redirected_to :root

    logout

    # not enabled
    with_config_value(:openbis_enabled, false) do
      project_admin = Factory(:project_administrator)
      project = project_admin.projects.first
      login_as(project_admin)
      get :browse, project_id: project.id
      assert_redirected_to :root
    end
  end


  test 'fetch spaces' do
    login_as(@project_administrator)
    post :fetch_spaces, project_id: @project.id,
         openbis_endpoint: {
             as_endpoint: 'https://openbis-api.fair-dom.org/openbis/openbis',
             dss_endpoint: 'https://openbis-api.fair-dom.org/datastore_server',
             web_endpoint: 'https://openbis-api.fair-dom.org/openbis',
             username: 'wibble',
             password: 'wobble' }
    assert_response :success
    assert @response.body.include?('API-SPACE')

    logout

    # normal project member cannot access
    person = Factory(:person)

    login_as(person)

    project = person.projects.first
    post :fetch_spaces, project_id: project.id, as_endpoint: 'https://openbis-api.fair-dom.org/openbis/openbis',
         dss_endpoint: 'https://openbis-api.fair-dom.org/datastore_server',
         web_endpoint: 'https://openbis-api.fair-dom.org/openbis',
         username: 'wibble',
         password: 'wobble'
    assert_response :redirect
    refute @response.body.include?('API-SPACE')

    # none project member cannot
    project = Factory(:project)
    post :fetch_spaces, project_id: project.id, as_endpoint: 'https://openbis-api.fair-dom.org/openbis/openbis',
         dss_endpoint: 'https://openbis-api.fair-dom.org/datastore_server',
         web_endpoint: 'https://openbis-api.fair-dom.org/openbis',
         username: 'wibble',
         password: 'wobble'
    assert_response :redirect
    refute @response.body.include?('API-SPACE')
  end

  test 'test endpoint' do
    login_as(@project_administrator)
    get :test_endpoint, project_id: @project.id,
        openbis_endpoint: {
            as_endpoint: 'https://openbis-api.fair-dom.org/openbis/openbis',
            dss_endpoint: 'https://openbis-api.fair-dom.org/datastore_server',
            web_endpoint: 'https://openbis-api.fair-dom.org/openbis',
            username: 'wibble',
            password: 'wobble' },
        format: :json
    assert_response :success
    assert @response.body.include?('true')

    logout

    # normal project member cannot access
    person = Factory(:person)

    login_as(person)

    project = person.projects.first
    get :test_endpoint, project_id: project.id,
        openbis_endpoint: {
            as_endpoint: 'https://openbis-api.fair-dom.org/openbis/openbis',
            dss_endpoint: 'https://openbis-api.fair-dom.org/datastore_server',
            web_endpoint: 'https://openbis-api.fair-dom.org/openbis',
            username: 'wibble',
            password: 'wobble' },
        format: :json
    assert_response 400
    refute @response.body.include?('true')

    # none project member cannot
    project = Factory(:project)
    get :test_endpoint, project_id: project.id, as_endpoint: 'https://openbis-api.fair-dom.org/openbis/openbis',
        dss_endpoint: 'https://openbis-api.fair-dom.org/datastore_server',
        web_endpoint: 'https://openbis-api.fair-dom.org/openbis',
        username: 'wibble',
        password: 'wobble',
        format: :json
    assert_response 400
    refute @response.body.include?('true')
  end


  test 'refresh metadata store' do
    login_as(@project_administrator)
    endpoint = Factory(:openbis_endpoint, project: @project)
    post :refresh, id: endpoint.id
    assert_redirected_to endpoint
  end

  test 'reset_fatal clears fatal stamps and marks for refresh' do
    login_as(@project_administrator)

    ep = Factory(:openbis_endpoint, project: @project)
    @zample = Seek::Openbis::Zample.new(ep, '20171002172111346-37')
    asset = OpenbisExternalAsset.build(@zample)

    #should ignore that
    asset.sync_state = :failed
    assert asset.save
    get :reset_fatals, id: ep.id
    assert_redirected_to ep
    asset.reload
    assert asset.failed?
    refute asset.fatal?

    asset.sync_state = :fatal
    assert asset.save

    get :reset_fatals, id: ep.id
    assert_redirected_to ep
    asset.reload
    refute asset.fatal?
    assert asset.refresh?



  end
end
