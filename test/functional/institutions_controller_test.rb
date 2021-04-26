require 'test_helper'

class InstitutionsControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases

  def setup
    login_as(:quentin)
  end

  def rest_api_test_object
    @object = institutions(:ebi_inst)
  end

  def test_title
    get :index
    assert_select 'title', text: 'Institutions', count: 1
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:institutions)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_institution
    assert_difference('Institution.count') do
      post :create, params: { institution: { title: 'test', country: 'FI' } }
    end

    assert_redirected_to institution_path(assigns(:institution))
  end

  def test_should_show_institution
    get :show, params: { id: institutions(:one).id }
    assert_response :success
  end

  def test_should_get_edit
    i = Factory(:institution)
    Factory(:avatar, owner: i)
    get :edit, params: { id: i }

    assert_response :success
  end

  def test_should_update_institution
    put :update, params: { id: institutions(:one).id, institution: { title: 'something' } }
    assert_redirected_to institution_path(assigns(:institution))
  end

  def test_should_destroy_institution
    institution = institutions(:four)
    get :show, params: { id: institution }
    assert_select '#buttons li', text: /delete institution/i, count: 1

    assert_difference('Institution.count', -1) do
      delete :destroy, params: { id: institution }
    end

    assert_redirected_to institutions_path
  end

  def test_non_admin_should_not_destroy_institution
    login_as(:aaron)
    institution = institutions(:four)
    get :show, params: { id: institution.id }
    assert_select 'span.icon', text: /Delete Institution/, count: 0
    assert_select 'span.disabled_icon', text: /Delete Institution/, count: 0
    assert_no_difference('Institution.count') do
      delete :destroy, params: { id: institution }
    end
    assert_not_nil flash[:error]
  end

  test 'can not destroy institution if it contains people' do
    institution = institutions(:four)
    work_group = Factory(:work_group, institution: institution)
    a_person = Factory(:person, group_memberships: [Factory(:group_membership, work_group: work_group)])
    institution.reload
    assert_includes institution.people, a_person
    get :show, params: { id: institution }
    assert_select 'span.disabled_icon', text: /Delete Institution/, count: 1
    assert_no_difference('Institution.count') do
      delete :destroy, params: { id: institution }
    end
    assert_not_nil flash[:error]
  end

  def test_project_administrator_can_edit
    project_admin = Factory(:project_administrator)
    institution = project_admin.institutions.first
    login_as(project_admin.user)
    get :show, params: { id: institution }
    assert_response :success
    assert_select 'a', text: /Edit Institution/, count: 1

    get :edit, params: { id: institution }
    assert_response :success

    put :update, params: { id: institution.id, institution: { title: 'something' } }
    assert_redirected_to institution_path(assigns(:institution))
  end

  def test_user_cant_edit_project
    login_as(Factory(:user))
    get :show, params: { id: institutions(:two) }
    assert_select 'a', text: /Edit Institution/, count: 0

    get :edit, params: { id: institutions(:two) }
    assert_response :redirect

    # TODO: Test for update
  end

  def test_admin_can_edit
    get :show, params: { id: institutions(:two) }
    assert_select 'a', text: /Edit Institution/, count: 1

    get :edit, params: { id: institutions(:two) }
    assert_response :success

    put :update, params: { id: institutions(:two).id, institution: { title: 'something' } }
    assert_redirected_to institution_path(assigns(:institution))
  end

  test 'project administrator can create institution' do
    login_as(Factory(:project_administrator).user)
    get :new
    assert_response :success

    assert_difference('Institution.count') do
      post :create, params: { institution: { title: 'a test institution', country: 'TH' } }
    end
  end

  test 'filtered by programme via nested route' do
    assert_routing 'programmes/4/institutions', controller: 'institutions', action: 'index', programme_id: '4'
    person1 = Factory(:person)
    person2 = Factory(:person)
    prog1 = Factory(:programme, projects: [person1.projects.first])
    prog2 = Factory(:programme, projects: [person2.projects.first])

    get :index, params: { programme_id: prog1.id }
    assert_response :success

    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', institution_path(person1.institutions.first), text: person1.institutions.first.title
      assert_select 'a[href=?]', institution_path(person2.institutions.first), text: person2.institutions.first.title, count: 0
    end
  end

  test 'project administrator can edit institution, which belongs to project they are project administrator, not necessary the institution they are in' do
    project_admin = Factory(:project_administrator)
    assert_equal 1, project_admin.projects.count
    project = project_admin.projects.first
    institution = Factory(:institution)
    project.institutions << institution

    assert project.institutions.include? institution
    assert !(project_admin.institutions.include? institution)

    login_as(project_admin.user)
    get :edit, params: { id: institution }
    assert_response :success

    put :update, params: { id: institution, institution: { title: 'test' } }
    assert_redirected_to institution
    institution.reload
    assert_equal 'test', institution.title
  end

  test "project administrator has a 'New Institution' link in the institution index" do
    login_as(Factory(:project_administrator).user)
    get :index
    assert_select 'div#content a[href=?]', new_institution_path, count: 1
  end

  test "non-project administrator  doesnt has a 'New Institution' link in the institution index" do
    get :index
    assert_select '#content a[href=?]', new_institution_path, count: 0
  end

  test 'activity logging' do
    person = Factory(:project_administrator)
    institution = person.institutions.first
    login_as(person)

    assert_difference('ActivityLog.count') do
      get :show, params: { id: institution.id }
    end

    log = ActivityLog.last
    assert_equal institution, log.activity_loggable
    assert_equal 'show', log.action
    assert_equal person.user, log.culprit

    assert_difference('ActivityLog.count') do
      put :update, params: { id: institution.id, institution: { title: 'fishy project' } }
    end

    log = ActivityLog.last
    assert_equal institution, log.activity_loggable
    assert_equal 'update', log.action
    assert_equal person.user, log.culprit
  end

  def edit_max_object(inst)
    for i in 1..5 do
      Factory(:person).add_to_project_and_institution(Factory(:project), inst)
    end
    add_avatar_to_test_object(inst)
  end

  test 'should create with discussion link' do
    person = Factory(:admin)
    login_as(person)
    assert_difference('AssetLink.discussion.count') do
      assert_difference('Institution.count') do
        post :create, params: { institution: { title: 'test',
                                               discussion_links_attributes: [{url: "http://www.slack.com/"}]}, }
      end
    end
    institution = assigns(:institution)
    assert_equal 'http://www.slack.com/', institution.discussion_links.first.url
    assert_equal AssetLink::DISCUSSION, institution.discussion_links.first.link_type
  end

  test 'should show discussion link' do
    disc_link = Factory(:discussion_link)
    institution = Factory(:institution)
    institution.discussion_links = [disc_link]
    get :show, params: { id: institution }
    assert_response :success
    assert_select 'div.panel-heading', text: /Discussion Channel/, count: 1
  end

  test 'should update node with discussion link' do
    person = Factory(:admin)
    institution = Factory(:institution)
    login_as(person)
    assert_nil institution.discussion_links.first
    assert_difference('AssetLink.discussion.count') do
      assert_difference('ActivityLog.count') do
        put :update, params: { id: institution.id, institution: { discussion_links_attributes:[{url: "http://www.slack.com/"}] } }
      end
    end
    assert_redirected_to institution_path(assigns(:institution))
    assert_equal 'http://www.slack.com/', institution.discussion_links.first.url
  end

  test 'should destroy related assetlink when the discussion link is removed ' do
    person = Factory(:admin)
    login_as(person)
    asset_link = Factory(:discussion_link)
    institution = Factory(:institution)
    institution.discussion_links = [asset_link]
    assert_difference('AssetLink.discussion.count', -1) do
      put :update, params: { id: institution.id, institution: { discussion_links_attributes:[{id:asset_link.id, _destroy:'1'}] } }
    end
    assert_redirected_to institution_path(institution = assigns(:institution))
    assert_empty institution.discussion_links
  end

end
