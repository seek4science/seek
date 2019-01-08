require 'test_helper'
require 'minitest/mock'

class WorkflowsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  include SharingFormTestHelper
  include GeneralAuthorizationTestCases

  def setup
    login_as Factory(:user)
    @project = User.current_user.person.projects.first
  end

  test 'index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:workflows)
  end

  test 'can create with valid url' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://somewhere.com/piccy.png'
    workflow_attrs = Factory.attributes_for(:workflow,
                                                project_ids: [@project.id]
                                               )

    assert_difference 'Workflow.count' do
      post :create, workflow: workflow_attrs, content_blobs: [{ data_url: 'http://somewhere.com/piccy.png', data: nil }], sharing: valid_sharing
    end
  end

  test 'can create with local file' do
    workflow_attrs = Factory.attributes_for(:workflow,
                                                contributor: User.current_user,
                                                project_ids: [@project])

    assert_difference 'Workflow.count' do
      assert_difference 'ActivityLog.count' do
        post :create, workflow: workflow_attrs, content_blobs: [{ data: file_for_upload }], sharing: valid_sharing
      end
    end
  end

  test 'can edit' do
    workflow = Factory :workflow, contributor: User.current_user.person

    get :edit, id: workflow
    assert_response :success
  end

  test 'can update' do
    workflow = Factory :workflow, contributor: User.current_user.person
    post :update, id: workflow, workflow: { title: 'updated' }
    assert_redirected_to workflow_path(workflow)
  end

  test 'can upload new version with valid url' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://somewhere.com/piccy.png'
    workflow = Factory :workflow, contributor: User.current_user.person

    assert_difference 'workflow.version' do
      post :new_version, id: workflow, workflow: {},
                         content_blobs: [{ data_url: 'http://somewhere.com/piccy.png' }]

      workflow.reload
    end
    assert_redirected_to workflow_path(workflow)
  end

  test 'can upload new version with valid filepath' do
    # by default, valid data_url is provided by content_blob in Factory
    workflow = Factory :workflow, contributor: User.current_user.person
    workflow.content_blob.url = nil
    workflow.content_blob.data = file_for_upload
    workflow.reload

    new_file_path = file_for_upload
    assert_difference 'workflow.version' do
      post :new_version, id: workflow, workflow: {}, content_blobs: [{ data: new_file_path }]

      workflow.reload
    end
    assert_redirected_to workflow_path(workflow)
  end

  test 'cannot upload file with invalid url' do
    stub_request(:head, 'http://www.blah.de/images/logo.png').to_raise(SocketError)
    workflow_attrs = Factory.build(:workflow, contributor: User.current_user.person).attributes # .symbolize_keys(turn string key to symbol)

    assert_no_difference 'Workflow.count' do
      post :create, workflow: workflow_attrs, content_blobs: [{ data_url: 'http://www.blah.de/images/logo.png' }]
    end
    assert_not_nil flash[:error]
  end

  test 'cannot upload new version with invalid url' do
    stub_request(:any, 'http://www.blah.de/images/liver-illustration.png').to_raise(SocketError)
    workflow = Factory :workflow, contributor: User.current_user.person
    new_data_url = 'http://www.blah.de/images/liver-illustration.png'
    assert_no_difference 'workflow.version' do
      post :new_version, id: workflow, workflow: {}, content_blobs: [{ data_url: new_data_url }]

      workflow.reload
    end
    assert_not_nil flash[:error]
  end

  test 'can destroy' do
    workflow = Factory :workflow, contributor: User.current_user.person
    content_blob_id = workflow.content_blob.id
    assert_difference('Workflow.count', -1) do
      delete :destroy, id: workflow
    end
    assert_redirected_to workflows_path

    # data/url is still stored in content_blob
    assert_not_nil ContentBlob.find_by_id(content_blob_id)
  end

  test 'can subscribe' do
    workflow = Factory :workflow, contributor: User.current_user.person
    assert_difference 'workflow.subscriptions.count' do
      workflow.subscribed = true
      workflow.save
    end
  end

  test 'update tags with ajax' do
    p = Factory :person

    login_as p.user

    p2 = Factory :person
    workflow = Factory :workflow, contributor: p

    assert workflow.annotations.empty?, 'this workflow should have no tags for the test'

    golf = Factory :tag, annotatable: workflow, source: p2.user, value: 'golf'
    Factory :tag, annotatable: workflow, source: p2.user, value: 'sparrow'

    workflow.reload

    assert_equal %w(golf sparrow), workflow.annotations.collect { |a| a.value.text }.sort
    assert_equal [], workflow.annotations.select { |a| a.source == p.user }.collect { |a| a.value.text }.sort
    assert_equal %w(golf sparrow), workflow.annotations.select { |a| a.source == p2.user }.collect { |a| a.value.text }.sort

    xml_http_request :post, :update_annotations_ajax, id: workflow, tag_list: "soup,#{golf.value.text}"

    workflow.reload

    assert_equal %w(golf soup sparrow), workflow.annotations.collect { |a| a.value.text }.uniq.sort
    assert_equal %w(golf soup), workflow.annotations.select { |a| a.source == p.user }.collect { |a| a.value.text }.sort
    assert_equal %w(golf sparrow), workflow.annotations.select { |a| a.source == p2.user }.collect { |a| a.value.text }.sort
  end

  test 'should set the other creators ' do
    user = Factory(:user)
    workflow = Factory(:workflow, contributor: user.person)
    login_as(user)
    assert workflow.can_manage?, 'The workflow must be manageable for this test to succeed'
    put :update, id: workflow, workflow: { other_creators: 'marry queen' }
    workflow.reload
    assert_equal 'marry queen', workflow.other_creators
  end

  test 'should show the other creators on the workflow index' do
    Factory(:workflow, policy: Factory(:public_policy), other_creators: 'another creator')
    get :index
    assert_select 'p.list_item_attribute', text: /: another creator/, count: 1
  end

  test 'should show the other creators in -uploader and creators- box' do
    workflow = Factory(:workflow, policy: Factory(:public_policy), other_creators: 'another creator')
    get :show, id: workflow
    assert_select 'div', text: 'another creator', count: 1
  end

  test 'filter by people, including creators, using nested routes' do
    assert_routing 'people/7/workflows', controller: 'workflows', action: 'index', person_id: '7'

    person1 = Factory(:person)
    person2 = Factory(:person)

    pres1 = Factory(:workflow, contributor: person1, policy: Factory(:public_policy))
    pres2 = Factory(:workflow, contributor: person2, policy: Factory(:public_policy))

    pres3 = Factory(:workflow, contributor: Factory(:person), creators: [person1], policy: Factory(:public_policy))
    pres4 = Factory(:workflow, contributor: Factory(:person), creators: [person2], policy: Factory(:public_policy))

    get :index, person_id: person1.id
    assert_response :success

    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', workflow_path(pres1), text: pres1.title
      assert_select 'a[href=?]', workflow_path(pres3), text: pres3.title

      assert_select 'a[href=?]', workflow_path(pres2), text: pres2.title, count: 0
      assert_select 'a[href=?]', workflow_path(pres4), text: pres4.title, count: 0
    end
  end

  test 'should display null license text' do
    workflow = Factory :workflow, policy: Factory(:public_policy)

    get :show, id: workflow

    assert_select '.panel .panel-body span#null_license', text: I18n.t('null_license')
  end

  test 'should display license' do
    workflow = Factory :workflow, license: 'CC-BY-4.0', policy: Factory(:public_policy)

    get :show, id: workflow

    assert_select '.panel .panel-body a', text: 'Creative Commons Attribution 4.0'
  end

  test 'should display license for current version' do
    workflow = Factory :workflow, license: 'CC-BY-4.0', policy: Factory(:public_policy)
    workflowv = Factory :workflow_version_with_blob, workflow: workflow

    workflow.update_attributes license: 'CC0-1.0'

    get :show, id: workflow, version: 1
    assert_response :success
    assert_select '.panel .panel-body a', text: 'Creative Commons Attribution 4.0'

    get :show, id: workflow, version: workflowv.version
    assert_response :success
    assert_select '.panel .panel-body a', text: 'CC0 1.0'
  end

  test 'should update license' do
    user = Factory(:person).user
    login_as(user)
    workflow = Factory :workflow, policy: Factory(:public_policy), contributor: user.person

    assert_nil workflow.license

    put :update, id: workflow, workflow: { license: 'CC-BY-SA-4.0' }

    assert_response :redirect

    get :show, id: workflow
    assert_select '.panel .panel-body a', text: 'Creative Commons Attribution Share-Alike 4.0'
    assert_equal 'CC-BY-SA-4.0', assigns(:workflow).license
  end

  test 'programme workflows through nested routing' do
    assert_routing 'programmes/2/workflows', controller: 'workflows', action: 'index', programme_id: '2'
    programme = Factory(:programme, projects: [@project])
    assert_equal [@project], programme.projects
    workflow = Factory(:workflow, policy: Factory(:public_policy), contributor:User.current_user.person)
    workflow2 = Factory(:workflow, policy: Factory(:public_policy))

    get :index, programme_id: programme.id

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', workflow_path(workflow), text: workflow.title
      assert_select 'a[href=?]', workflow_path(workflow2), text: workflow2.title, count: 0
    end
  end

  def edit_max_object(workflow)
    add_tags_to_test_object(workflow)
    add_creator_to_test_object(workflow)
  end

end
