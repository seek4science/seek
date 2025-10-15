require 'test_helper'

class InstitutionsControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:quentin)
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

  def test_should_create_institution_with_ror_id
    VCR.use_cassette("ror/fetch_by_id") do
      assert_difference('Institution.count') do
        post :create, params: { institution: { ror_id:'03vek6s52' } }
      end
    end
    assert_redirected_to institution_path(assigns(:institution))
    assert_equal 'Harvard University', assigns(:institution).title
    assert_equal 'US', assigns(:institution).country
    assert_equal '03vek6s52', assigns(:institution).ror_id
  end

  def test_should_create_institution_with_title

    assert_difference('Institution.count') do
      post :create, params: { institution: { title: 'test' } }
    end

    assert_redirected_to institution_path(assigns(:institution))
    assert_equal 'test', assigns(:institution).title

    get :show, params: { id: assigns(:institution) }
    assert_select 'h1', text: 'test', count: 1


    assert_difference('Institution.count') do
      post :create, params: { institution: { title: 'University of Manchester', department: 'Manchester Institute of Biotechnology'} }
    end

    institution = assigns(:institution)

    assert_redirected_to institution_path(assigns(:institution))
    assert_equal 'Manchester Institute of Biotechnology, University of Manchester', institution.title

    get :show, params: { id: institution }
    assert_select 'h1', text: 'Manchester Institute of Biotechnology, University of Manchester', count: 1

    get :edit, params: { id: institution }
    assert_response :success
    assert_select 'input#institution_title[value=?]', 'University of Manchester'

  end


  def test_should_create_institution_with_or_without_title_department_

    # If creating a new institution with a title first,
    # it should still be possible to create another institution with the same title but a different department.
    assert_difference('Institution.count') do
      post :create, params: { institution: { title: 'Institution 1', department: 'Division 1' } }
    end

    assert_redirected_to institution_path(assigns(:institution))
    assert_equal 'Division 1', assigns(:institution).department
    assert_equal 'Division 1, Institution 1', assigns(:institution).title

    get :show, params: { id: assigns(:institution) }
    assert_select 'h1', text: 'Division 1, Institution 1', count: 1

    assert_difference('Institution.count') do
      post :create, params: { institution: { title: 'Institution 1' }}
    end

    assert_equal 'Institution 1', assigns(:institution).title

    get :show, params: { id: assigns(:institution) }
    assert_select 'h1', text: 'Institution 1', count: 1


    assert_difference('Institution.count') do
      post :create, params: { institution: { title: 'Institution 1',department: 'Division 2' }}
    end

    assert_equal 'Division 2, Institution 1', assigns(:institution).title

    # If creating a new institution with a title and a department first,
    # it should still be possible to create another institution with the title but without a different department.
    assert_difference('Institution.count') do
      post :create, params: { institution: { title: 'Institution 2' }}
    end

    assert_equal 'Institution 2', assigns(:institution).title

    get :show, params: { id: assigns(:institution) }
    assert_select 'h1', text: 'Institution 2', count: 1

    assert_difference('Institution.count') do
      post :create, params: { institution: { title: 'Institution 2', department: 'Division 2' } }
    end

    assert_redirected_to institution_path(assigns(:institution))
    assert_equal 'Division 2', assigns(:institution).department
    assert_equal 'Division 2, Institution 2', assigns(:institution).title

    get :show, params: { id: assigns(:institution) }
    assert_select 'h1', text: 'Division 2, Institution 2', count: 1

  end

  def test_should_not_create_institution_without_title
    assert_no_difference('Institution.count') do
      post :create, params: { institution: { department: 'Some Department' } }
    end
    assert_includes assigns(:institution).errors[:title], "can't be blank"

  end



  def test_can_not_create_institution_with_invalid_ror_id
    VCR.use_cassette("ror/fetch_invalid_id") do
      assert_no_difference('Institution.count') do
        post :create, params: { institution: { title: 'test', ror_id: 'invalid_id' } }
      end
    end
    assert_equal assigns(:institution).errors[:ror_id].first, "'invalid_id' is not a valid ROR ID"
  end


  def test_can_not_create_institution_with_the_title_or_ror_id_that_already_exists
    VCR.use_cassette("ror/existing_institution") do
      FactoryBot.create(:institution, title: 'Harvard University', ror_id: '03vek6s52')

      assert_no_difference('Institution.count') do
        post :create, params: { institution: { title: 'Harvard University' } }
      end
      assert_equal assigns(:institution).errors[:title].first, 'has already been taken'

      assert_no_difference('Institution.count') do
        post :create, params: { institution: { ror_id: '03vek6s52' } }
      end
      assert_equal assigns(:institution).errors[:ror_id].first, 'has already been taken'
    end
  end

  def test_can_create_institution_with_the_title_or_ror_id_that_already_exists_but_different_department
    VCR.use_cassette("ror/existing_institution") do
      FactoryBot.create(:institution, title: 'Harvard University', ror_id: '03vek6s52')

      assert_difference('Institution.count') do
        post :create, params: { institution: { title: 'Harvard University', department: "Applied Mathematics"} }
      end

      assert_redirected_to institution_path(assigns(:institution))
      assert_equal 'Applied Mathematics, Harvard University', assigns(:institution).title
      assert_equal 'Applied Mathematics', assigns(:institution).department

      assert_difference('Institution.count') do
        post :create, params: { institution: { ror_id: '03vek6s52', department: "Computer Science"} }
      end

      assert_redirected_to institution_path(assigns(:institution))
      assert_equal 'Computer Science, Harvard University', assigns(:institution).title
      assert_equal 'Computer Science', assigns(:institution).department
      assert_equal '03vek6s52', assigns(:institution).ror_id

    end
  end

  def test_should_show_institution
    get :show, params: { id: institutions(:one).id }
    assert_response :success
  end

  def test_should_get_edit
    i = FactoryBot.create(:institution)
    FactoryBot.create(:avatar, owner: i)
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
    work_group = FactoryBot.create(:work_group, institution: institution)
    a_person = FactoryBot.create(:person, group_memberships: [FactoryBot.create(:group_membership, work_group: work_group)])
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
    project_admin = FactoryBot.create(:project_administrator)
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
    login_as(FactoryBot.create(:user))
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
    login_as(FactoryBot.create(:project_administrator).user)
    get :new
    assert_response :success

    assert_difference('Institution.count') do
      post :create, params: { institution: { title: 'a test institution', country: 'TH' } }
    end
  end

  test 'filtered by programme via nested route' do
    assert_routing 'programmes/4/institutions', controller: 'institutions', action: 'index', programme_id: '4'
    person1 = FactoryBot.create(:person)
    person2 = FactoryBot.create(:person)
    prog1 = FactoryBot.create(:programme, projects: [person1.projects.first])
    prog2 = FactoryBot.create(:programme, projects: [person2.projects.first])

    get :index, params: { programme_id: prog1.id }
    assert_response :success

    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', institution_path(person1.institutions.first), text: person1.institutions.first.title
      assert_select 'a[href=?]', institution_path(person2.institutions.first), text: person2.institutions.first.title, count: 0
    end
  end

  test 'project administrator can edit institution, which belongs to project they are project administrator, not necessary the institution they are in' do
    project_admin = FactoryBot.create(:project_administrator)
    assert_equal 1, project_admin.projects.count
    project = project_admin.projects.first
    institution = FactoryBot.create(:institution)
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
    login_as(FactoryBot.create(:project_administrator).user)
    get :index
    assert_select 'div#content a[href=?]', new_institution_path, count: 1
  end

  test "non-project administrator  doesnt has a 'New Institution' link in the institution index" do
    get :index
    assert_select '#content a[href=?]', new_institution_path, count: 0
  end

  test 'activity logging' do
    person = FactoryBot.create(:project_administrator)
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

  test 'should create with discussion link' do
    person = FactoryBot.create(:admin)
    login_as(person)
    assert_difference('AssetLink.discussion.count') do
      assert_difference('Institution.count') do
        post :create, params: { institution: { title: 'test',
                                               country: 'TH',
                                               discussion_links_attributes: [{url: "http://www.slack.com/"}]}, }
      end
    end
    institution = assigns(:institution)
    assert_equal 'http://www.slack.com/', institution.discussion_links.first.url
    assert_equal AssetLink::DISCUSSION, institution.discussion_links.first.link_type
  end

  test 'should show discussion link' do
    disc_link = FactoryBot.create(:discussion_link)
    institution = FactoryBot.create(:institution)
    institution.discussion_links = [disc_link]
    get :show, params: { id: institution }
    assert_response :success
    assert_select 'div.panel-heading', text: /Discussion Channel/, count: 1
  end

  test 'should update node with discussion link' do
    person = FactoryBot.create(:admin)
    institution = FactoryBot.create(:institution)
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

  test 'should destroy related assetlink when the discussion link is removed' do
    person = FactoryBot.create(:admin)
    login_as(person)
    asset_link = FactoryBot.create(:discussion_link)
    institution = FactoryBot.create(:institution)
    institution.discussion_links = [asset_link]
    assert_difference('AssetLink.discussion.count', -1) do
      put :update, params: { id: institution.id, institution: { discussion_links_attributes:[{id:asset_link.id, _destroy:'1'}] } }
    end
    assert_redirected_to institution_path(institution = assigns(:institution))
    assert_empty institution.discussion_links
  end

  test 'request all sharing form' do
    Institution.delete_all
    institutions = [FactoryBot.create(:institution),FactoryBot.create(:institution),FactoryBot.create(:institution)]
    get :request_all_sharing_form, format: :json
    assert_response :success
    expected = institutions.collect{|i| [i.title, i.id]}
    actual = JSON.parse(response.body)['institution_list']
    assert_equal expected, actual
  end


  test 'should query institution name via ror' do
    VCR.use_cassette("ror/query_harvard_by_name") do
      get :ror_search, params: { query: 'Harvard' }
      assert_response :success
      res = JSON.parse(response.body)
      assert res.key?('items'), 'Response should contain items key'
      assert res['items'].is_a?(Array), 'Items should be an array'
      assert res['items'].any?, 'Items array should not be empty'
    end
  end


  test 'should fetch institution metadata with ror id' do
    VCR.use_cassette("ror/fetch_by_id") do
      get :ror_search, params: { ror_id: '03vek6s52' }
      assert_response :success
      res = JSON.parse(response.body)
      assert_equal '03vek6s52', res["id"]
      assert_equal 'Harvard University', res["name"]
      assert_equal 'education', res["type"]
      assert_equal 'Universidad de Harvard', res["altNames"]
      assert_equal 'United States', res["country"]
      assert_equal 'US', res["countrycode"]
      assert_equal 'Cambridge', res["city"]
      assert_equal 'https://www.harvard.edu', res["webpage"]
    end
  end


  test 'should return an empty result when querying a nonexistent institution' do
    VCR.use_cassette("ror/ror_nonexistent_institution") do
      get :ror_search, params: { query: 'nonexistentuniversity123' }
      assert_response :success
      res = JSON.parse(response.body)
      assert_empty res["items"]
    end
  end

  test 'should return an error when ror id is invalid' do
    VCR.use_cassette("ror/fetch_invalid_id") do
      get :ror_search, params: { ror_id: 'invalid_id' }
      assert_response :internal_server_error
      assert_includes response.body, "'invalid_id' is not a valid ROR ID"
    end
  end

  test 'should return an error when ror id is missing' do
    get :ror_search
    assert_response :bad_request
    assert_equal({ error: 'Missing ROR ID' }.to_json, response.body)
  end


end
