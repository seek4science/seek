require 'test_helper'

class PeopleControllerTest < ActionController::TestCase
  fixtures :people, :users, :projects, :work_groups, :group_memberships, :project_positions, :institutions

  include AuthenticatedTestHelper
  include RestTestCases
  include ApplicationHelper
  include RdfTestCases

  def setup
    login_as(:quentin)
  end

  def rest_api_test_object
    @object = Factory(:person, orcid: 'http://orcid.org/0000-0003-2130-0865')
  end

  def test_title
    get :index
    assert_select 'title', text: 'People', count: 1
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:people)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_first_registered_person_is_admin_and_default_project
    Person.destroy_all
    Project.delete_all

    project = Factory(:work_group).project
    refute_empty project.institutions
    institution = project.institutions.first
    refute_nil(institution)

    assert_equal 0, Person.count, 'There should be no people in the database'
    user = Factory(:activated_user)
    login_as user

    assert_difference('Person.count') do
      assert_difference('NotifieeInfo.count') do
        post :create, params: { person: { first_name: 'test', email: 'hghg@sdfsd.com' } }
      end
    end
    assert assigns(:person)
    person = Person.find(assigns(:person).id)
    assert person.is_admin?
    assert person.only_first_admin_person?
    assert_equal [project], person.projects
    assert_equal [institution], person.institutions
    assert_redirected_to registration_form_admin_path(during_setup: 'true')
  end

  test 'trim the email to avoid validation error' do
    login_as(Factory(:admin))
    assert_difference('Person.count') do
      post :create, params: { person: { first_name: 'test', email: ' hghg@sdfsd.com ' } }
    end
    assert person = assigns(:person)
    assert_equal 'hghg@sdfsd.com', person.email
  end

  def test_second_registered_person_is_not_admin
    Person.delete_all
    person = Factory(:brand_new_person, first_name: 'fred', email: 'fred@dddd.com')
    assert_equal 1, Person.count, 'There should be 1 person in the database'
    user = Factory(:activated_user)
    login_as user
    assert_difference('Person.count') do
      assert_difference('NotifieeInfo.count') do
        post :create, params: { person: { first_name: 'test', email: 'hghg@sdfsd.com' } }
      end
    end
    assert assigns(:person)
    person = Person.find(assigns(:person).id)
    refute person.is_admin?
    refute person.only_first_admin_person?
    assert_redirected_to person_path(person)
  end

  def test_should_create_person
    assert_difference('Person.count') do
      assert_difference('NotifieeInfo.count') do
        post :create, params: { person: { first_name: 'test', email: 'hghg@sdfsd.com' } }
      end
    end

    assert_redirected_to person_path(assigns(:person))
    assert_equal 'T', assigns(:person).first_letter
    assert_not_nil Person.find(assigns(:person).id).notifiee_info
  end

  test 'cannot access select form as registered user, even admin' do
    login_as Factory(:admin)
    get :register
    assert_redirected_to(root_path)
    refute_nil flash[:error]
  end

  test 'should reload form for incomplete details' do
    new_user = Factory(:brand_new_user)
    assert new_user.person.nil?

    login_as(new_user)

    assert_no_difference('Person.count') do
      post :create, params: { person: { first_name: 'test' } }
    end
    assert_response :success

    assert_select 'div#errorExplanation' do
      assert_select 'ul > li', text: "Email can't be blank"
    end
    assert_select 'form#new_person' do
      assert_select 'input#person_first_name[value=?]', 'test'
    end
  end

  def test_should_create_person_with_project
    work_group_id = Factory(:work_group).id
    assert_difference('Person.count') do
      assert_difference('NotifieeInfo.count') do
        post :create, params: { person: { first_name: 'test', email: 'hghg@sdfsd.com' } }
      end
    end

    assert_redirected_to person_path(assigns(:person))
    assert_equal 'T', assigns(:person).first_letter
  end

  def test_created_person_should_receive_notifications
    post :create, params: { person: { first_name: 'test', email: 'hghg@sdfsd.com' } }
    p = assigns(:person)
    assert_not_nil p.notifiee_info
    assert p.notifiee_info.receive_notifications?
  end

  def test_should_show_person
    get :show, params: { id: people(:quentin_person) }
    assert_response :success
  end

  test 'virtual liver hides access to index people page for logged out user' do
    with_config_value 'is_virtualliver', true do
      Factory :person, first_name: 'Invisible', last_name: ''
      logout
      get :index
      assert_select 'a', text: /Invisible/, count: 0
    end
  end

  def test_should_get_edit
    get :edit, params: { id: people(:quentin_person) }
    assert_response :success
  end

  def test_non_admin_cant_edit_someone_else
    login_as(:fred)
    get :edit, params: { id: people(:aaron_person) }
    assert_redirected_to people(:aaron_person)
  end

  test 'project administrator can edit userless-profiles in their project' do
    project_admin = Factory(:project_administrator)
    unregistered_person = Factory(:brand_new_person,
                                  group_memberships: [Factory(:group_membership,
                                                              work_group: project_admin.group_memberships.first.work_group)])
    refute (project_admin.projects & unregistered_person.projects).empty?,
           'Project administrator should belong to the same project as the person he is trying to edit'

    login_as(project_admin)

    get :edit, params: { id: unregistered_person.id }
    assert_response :success
  end

  test "project administrator cannot edit registered users' profiles in their project" do
    project_admin = Factory(:project_administrator)
    registered_person = Factory(:person,
                                group_memberships: [Factory(:group_membership,
                                                            work_group: project_admin.group_memberships.first.work_group)])
    refute (project_admin.projects & registered_person.projects).empty?,
           'Project administrator should belong to the same project as the person he is trying to edit'

    login_as(project_admin)

    get :edit, params: { id: registered_person.id }
    assert_response :redirect
    assert_not_empty flash[:error]
  end

  def test_admin_can_edit_others
    get :edit, params: { id: people(:aaron_person) }
    assert_response :success
  end

  def test_change_notification_settings
    p = Factory(:person)
    assert p.notifiee_info.receive_notifications?, 'should receive notifications by default in fixtures'

    put :update, params: { id: p.id, person: { description: p.description } }
    refute Person.find(p.id).notifiee_info.receive_notifications?

    put :update, params: { id: p.id, person: { description: p.description }, receive_notifications: true }
    assert Person.find(p.id).notifiee_info.receive_notifications?
  end

  def test_can_edit_person_and_user_id_different
    # where a user_id for a person are not the same
    login_as(:fred)
    get :edit, params: { id: people(:fred) }
    assert_response :success
  end

  def test_current_user_shows_login_name
    current_user = Factory(:person).user
    login_as(current_user)
    get :show, params: { id: current_user.person }
    assert_select '.box_about_actor p', text: /Login/m
    assert_select '.box_about_actor p', text: /Login.*#{current_user.login}/m
  end

  def test_not_current_user_doesnt_show_login_name
    current_user = Factory(:person).user
    other_person = Factory(:person)
    login_as(current_user)
    get :show, params: { id: other_person }
    assert_select '.box_about_actor p', text: /Login/m, count: 0
  end

  def test_admin_sees_non_current_user_login_name
    current_user = Factory(:admin).user
    other_person = Factory(:person)
    login_as(current_user)
    get :show, params: { id: other_person }
    assert_select '.box_about_actor p', text: /Login/m
    assert_select '.box_about_actor p', text: /Login.*#{other_person.user.login}/m
  end

  def test_should_update_person
    put :update, params: { id: people(:quentin_person), person: { description: 'a' } }
    assert_redirected_to person_path(assigns(:person))
  end

  def test_should_not_update_somebody_else_if_not_admin
    login_as(:aaron)
    quentin = people(:quentin_person)
    put :update, params: { id: people(:quentin_person), person: { email: 'kkkkk@kkkkk.com' } }
    assert_not_nil flash[:error]
    quentin.reload
    assert_equal 'quentin@email.com', quentin.email
  end

  def test_should_destroy_person
    assert_difference('Person.count', -1) do
      delete :destroy, params: { id: people(:quentin_person) }
    end

    assert_redirected_to people_path
  end

  def test_should_add_nofollow_to_links_in_show_page
    get :show, params: { id: people(:person_with_links_in_description) }
    assert_select 'div#description' do
      assert_select 'a[rel="nofollow"]'
    end
  end

  test 'filtering by project' do
    project = projects(:sysmo_project)
    get :index, params: { filter: { project: project.id } }
    assert_response :success
  end

  test 'finding by role' do
    p1 = Factory(:pal)
    p2 = Factory(:person)
    get :index, params: { filter: { project_position: ProjectPosition.pal_position.id } }
    assert_response :success
    assert assigns(:people)
    assert assigns(:people).include?(p1)
    refute assigns(:people).include?(p2)
  end

  test 'admin can manage person' do
    login_as(:quentin)
    person = people(:aaron_person)
    assert person.can_manage?
  end

  test 'non-admin users + anonymous users can not manage person ' do
    login_as(:aaron)
    person = people(:quentin_person)
    refute person.can_manage?

    logout
    refute person.can_manage?
  end

  test 'should remove every permissions set on the person before deleting him' do
    login_as(:quentin)
    person = Factory(:person)
    # create bunch of permissions on this person
    i = 0
    while i < 10
      Factory(:permission, contributor: person, access_type: rand(5))
      i += 1
    end
    permissions = Permission.where(contributor_type: 'Person', contributor_id: person.try(:id))
    assert_equal 10, permissions.count

    assert_difference('Person.count', -1) do
      delete :destroy, params: { id: person }
    end

    permissions = Permission.where(contributor_type: 'Person', contributor_id: person.try(:id))
    assert_equal 0, permissions.count
  end

  test 'should set the manage right on pi before deleting the person' do
    login_as(:quentin)

    project = Factory(:project)
    work_group = Factory(:work_group, project: project)
    person = Factory(:person_in_project, group_memberships: [Factory(:group_membership, work_group: work_group)])
    user = Factory(:user, person: person)
    # create a datafile that this person is the contributor
    data_file = Factory(:data_file, contributor: user.person, project_ids: [project.id])
    # create pi
    position = ProjectPosition.find_by_name('PI')
    pi = Factory(:person_in_project, group_memberships: [Factory(:group_membership, work_group: work_group)])
    pi.group_memberships.first.project_positions << position
    pi.save
    assert_equal pi, project.pis.first

    assert_difference('Person.count', -1) do
      delete :destroy, params: { id: person }
    end

    permissions_on_person = Permission.where(contributor_type: 'Person', contributor_id: person.try(:id))
    assert_equal 0, permissions_on_person.count

    permissions = data_file.policy.permissions

    assert_equal 1, permissions.count
    assert_equal pi.id, permissions.first.contributor_id
    assert_equal Policy::MANAGING, permissions.first.access_type
  end

  test 'should set the manage right on pal (if no pi) before deleting the person' do
    login_as(:quentin)

    project = Factory(:project)
    work_group = Factory(:work_group, project: project)
    person = Factory(:person_in_project, group_memberships: [Factory(:group_membership, work_group: work_group)])
    user = Factory(:user, person: person)
    # create a datafile that this person is the contributor and with the same project
    data_file = Factory(:data_file, contributor: user.person, project_ids: [project.id])
    # create pal
    position = ProjectPosition.find_by_name('Sysmo-DB Pal')
    pal = Factory(:person_in_project, group_memberships: [Factory(:group_membership, work_group: work_group)])
    pal.group_memberships.first.project_positions << position
    pal.is_pal = true, project
    pal.save
    assert_equal pal, project.pals.first
    assert_equal 0, project.pis.count

    assert_difference('Person.count', -1) do
      delete :destroy, params: { id: person }
    end

    permissions_on_person = Permission.where(contributor_type: 'Person', contributor_id: person.try(:id))
    assert_equal 0, permissions_on_person.count

    permissions = data_file.policy.permissions

    assert_equal 1, permissions.count
    assert_equal pal.id, permissions.first.contributor_id
    assert_equal Policy::MANAGING, permissions.first.access_type
  end

  test 'should have asset housekeeper role on person show page' do
    asset_housekeeper = Factory(:asset_housekeeper)
    get :show, params: { id: asset_housekeeper }
    assert_select '#project-roles h3 img[src*=?]', role_image(:asset_housekeeper), count: 1
  end

  test 'should have asset housekeeper icon on people index page' do
    6.times do
      Factory(:asset_housekeeper)
    end

    get :index, params: { page: 'all' }

    asset_housekeeper_number = assigns(:people).select(&:is_asset_housekeeper_of_any_project?).count
    assert_select 'img[src*=?]', role_image(:asset_housekeeper), count: asset_housekeeper_number
  end

  test 'should have project administrator role on person show page' do
    project_administrator = Factory(:project_administrator)
    get :show, params: { id: project_administrator }
    assert_select '#project-roles h3 img[src*=?]', role_image(:project_administrator), count: 1
  end

  test 'should have project administrator icon on people index page' do
    6.times do
      Factory(:project_administrator)
    end

    get :index, params: { page: 'all' }

    project_administrator_count = assigns(:people).select(&:is_project_administrator_of_any_project?).count
    assert_select 'img[src*=?]', role_image(:project_administrator), count: project_administrator_count
  end

  test 'allow project administrator to edit unregistered people inside their projects, even outside their institutions' do
    project_admin = Factory(:project_administrator)
    project = project_admin.projects.first
    person = Factory(:brand_new_person,
                     group_memberships: [Factory(:group_membership,
                                                 work_group: Factory(:work_group, project: project))])
    assert_includes project_admin.projects, person.projects.first, 'they should be in the same project'
    refute_includes project_admin.institutions, person.institutions.first, 'they should not be in the same institution'
    assert_equal 1, person.institutions.count, 'should only be in 1 project'

    assert project_admin.is_project_administrator?(project)

    login_as(project_admin)
    get :edit, params: { id: person }

    assert_response :success

    put :update, params: { id: person, person: { first_name: 'blabla' } }

    assert_redirected_to person_path(assigns(:person))
    person = assigns(:person)
    assert_equal 'blabla', person.first_name
  end

  test 'project administrator can view profile creation' do
    login_as(Factory(:project_administrator))
    get :new
    assert_response :success
  end

  test 'project administrator can create new profile' do
    login_as(Factory(:project_administrator))
    assert_difference('Person.count') do
      post :create, params: { person: { first_name: 'test', email: 'ttt@email.com' } }
    end
    person = assigns(:person)
    refute_nil person
    assert_equal 'test', person.first_name
    assert_equal 'ttt@email.com', person.email
  end

  test 'normal user cannot can view profile creation' do
    login_as(Factory(:person))
    get :new
    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test 'normal user cannot create new profile' do
    login_as(Factory(:person))
    assert_no_difference('Person.count') do
      post :create, params: { person: { first_name: 'test', email: 'ttt@email.com' } }
    end
    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test 'cannot update person roles mask' do
    login_as(Factory(:admin))
    person = Factory(:person)
    put :update, params: { id: person, person: { first_name: 'blabla', roles_mask: mask_for_admin } }
    assert_redirected_to person_path(assigns(:person))
    refute assigns(:person).is_admin?
    assert_equal 'blabla', assigns(:person).first_name
  end

  test 'not allow project administrator to edit people outside their projects' do
    project_admin = Factory(:project_administrator)
    a_person = Factory(:person)
    refute_includes project_admin.projects, a_person.projects.first, 'they should not be in the same project'
    assert_equal 1, a_person.projects.count, 'should by in only 1 project'

    login_as(project_admin)
    get :edit, params: { id: a_person }

    assert_response :redirect
    assert_not_nil flash[:error]

    put :update, params: { id: a_person, person: { first_name: 'blabla' } }

    assert_response :redirect
    assert_not_nil flash[:error]
    a_person.reload
    assert_not_equal 'blabla', a_person.first_name
  end

  test 'project administrator can not edit admin' do
    project_admin = Factory(:project_administrator)
    admin = Factory(:admin, group_memberships: [Factory(:group_membership, work_group: project_admin.group_memberships.first.work_group)])

    login_as(project_admin)
    get :show, params: { id: admin }
    assert_select 'a', text: /Edit Profile/, count: 0

    get :edit, params: { id: admin }

    assert_response :redirect
    assert_not_nil flash[:error]

    put :update, params: { id: admin, person: { first_name: 'blablba' } }

    assert_response :redirect
    assert_not_nil flash[:error]

    refute_equal 'blablba', assigns(:person).first_name
  end

  test 'admin can edit other admin' do
    admin = Factory(:admin)
    assert_not_nil admin.user
    assert_not_equal User.current_user, admin.user

    get :show, params: { id: admin }
    assert_select 'a', text: /Edit Profile/, count: 1

    get :edit, params: { id: admin }
    assert_response :success

    assert_not_equal 'test', admin.title
    put :update, params: { id: admin, person: { first_name: 'test' } }
    assert_redirected_to person_path(admin)
    assert_equal 'test', assigns(:person).first_name
  end

  test 'can edit themself' do
    login_as(:fred)
    get :show, params: { id: people(:fred) }
    assert_select 'a', text: /Edit Profile/, count: 1

    get :edit, params: { id: people(:fred) }
    assert_response :success

    put :update, params: { id: people(:fred), person: { first_name: 'fred1' } }
    assert_redirected_to assigns(:person)
    assert_equal 'fred1', assigns(:person).first_name
  end

  test 'if not admin login should not show the registered date for this person' do
    login_as(:aaron)
    a_person = Factory(:person)
    get :show, params: { id: a_person }
    assert_response :success
    assert_select 'p', text: /#{date_as_string(a_person.user.created_at)}/, count: 0

    get :index
    assert_response :success
    assigns(:people).each do |person|
      unless person.try(:user).try(:created_at).nil?
        assert_select 'p', text: /#{date_as_string(person.user.created_at)}/, count: 0
      end
    end
  end

  test 'should have gatekeeper role on person show page' do
    gatekeeper = Factory(:asset_gatekeeper)
    get :show, params: { id: gatekeeper }
    assert_select '#project-roles h3 img[src*=?]', role_image(:asset_gatekeeper), count: 1
  end

  test 'should have gatekeeper icon on people index page' do
    6.times do
      Factory(:asset_gatekeeper)
    end

    get :index, params: { page: 'all' }

    gatekeeper_number = assigns(:people).select(&:is_asset_gatekeeper_of_any_project?).count
    assert_select 'img[src*=?]', role_image(:asset_gatekeeper), count: gatekeeper_number
  end

  test 'unsubscribe to a project should unsubscribe all the items of that project' do
    with_config_value 'email_enabled', true do
      current_person = User.current_user.person
      proj = current_person.projects.first
      sop = Factory(:sop, projects: [proj], policy: Factory(:public_policy))
      df = Factory(:data_file, projects: [proj], policy: Factory(:public_policy))



      # subscribe to project
      put :update, params: { id: current_person, receive_notifications: true, person: { project_subscriptions_attributes: { '0' => { project_id: proj.id, frequency: 'weekly', _destroy: '0' } } } }
      assert_redirected_to current_person

      project_subscription = ProjectSubscription.where({project_id:proj.id, person_id:current_person.id}).first
      assert_difference 'Subscription.count', 2 do
        ProjectSubscriptionJob.new(project_subscription.id).perform
      end
      assert sop.subscribed?(current_person)
      assert df.subscribed?(current_person)
      assert current_person.receive_notifications?

      assert_enqueued_emails 1 do
        Factory(:activity_log, activity_loggable: sop, action: 'update')
        Factory(:activity_log, activity_loggable: df, action: 'update')
        SendPeriodicEmailsJob.new('weekly').perform
      end

      # unsubscribe to project
      put :update, params: { id: current_person, receive_notifications: true, person: { project_subscriptions_attributes: { '0' => { id: current_person.project_subscriptions.first.id, project_id: proj.id, frequency: 'weekly', _destroy: '1' } } } }
      assert_redirected_to current_person
      assert current_person.project_subscriptions.empty?

      sop.reload
      df.reload
      refute sop.subscribed?(current_person)
      refute df.subscribed?(current_person)
      assert current_person.receive_notifications?

      assert_no_enqueued_emails do
        Factory(:activity_log, activity_loggable: sop, action: 'update')
        Factory(:activity_log, activity_loggable: df, action: 'update')
        SendPeriodicEmailsJob.new('weekly').perform
      end
    end
  end

  test 'should show subscription list to only yourself and admin' do
    a_person = Factory(:person)
    login_as(a_person.user)
    get :show, params: { id: a_person }
    assert_response :success
    assert_select 'div.panel-heading', text: 'Subscriptions', count: 1

    logout

    login_as(:quentin)
    get :show, params: { id: a_person }
    assert_response :success
    assert_select 'div.panel-heading', text: 'Subscriptions', count: 1
  end

  test 'should not show subscription list to people that are not yourself and admin' do
    a_person = Factory(:person)
    login_as(Factory(:user))
    get :show, params: { id: a_person }
    assert_response :success
    assert_select 'div.panel-heading', text: 'Subscriptions', count: 0

    logout

    get :show, params: { id: a_person }
    assert_response :success
    assert_select 'div.panel-heading', text: 'Subscriptions', count: 0
  end

  test 'virtual liver blocks access to profile page whilst logged out' do
    a_person = Factory(:person)
    logout
    as_virtualliver do
      get :show, params: { id: a_person }
      assert_response :forbidden
    end
  end

  test 'should update pagination when changing the relevant settings' do
    assert_not_equal 5, Seek::Config.results_per_page_for('people')
    assert_not_equal :created_at_asc, Seek::Config.sorting_for('people')

    with_config_value(:sorting, { 'people' => 'created_at_asc' }) do
      with_config_value(:results_per_page, { 'people' => 5 }) do
        assert_equal 5, Seek::Config.results_per_page_for('people')
        assert_equal :created_at_asc, Seek::Config.sorting_for('people')
        get :index
        assert_response :success
        assert_equal [:created_at_asc], assigns(:order)
        assert_equal 5, assigns(:per_page)
        assert_select '.pagination-container li.active', text: '1'
        assert_select 'div.list_item_title', count: 5
        assert_select '#index_sort_order option[selected=selected][value=created_at_asc]', count: 1
      end
    end
  end

  test 'controller-specific results_per_page should override default' do
    with_config_value(:results_per_page_default, 2) do
      get :index
      assert_response :success
      assert_equal 2, assigns(:per_page)
      assert_select '.pagination-container li.active', text: '1'
      assert_select 'div.list_item_title', count: 2

      with_config_value(:results_per_page, { 'people' => 3 }) do
        get :index
        assert_response :success
        assert_equal 3, assigns(:per_page)
        assert_select '.pagination-container li.active', text: '1'
        assert_select 'div.list_item_title', count: 3
      end

      with_config_value(:results_per_page, { 'people' => nil }) do
        get :index
        assert_response :success
        assert_equal 2, assigns(:per_page)
        assert_select '.pagination-container li.active', text: '1'
        assert_select 'div.list_item_title', count: 2
      end
    end
  end

  test 'people not in projects should be shown in index' do
    person_not_in_project = Factory(:brand_new_person, first_name: 'Person Not In Project', last_name: 'Petersen', updated_at: 1.second.from_now)
    person_in_project = Factory(:person, first_name: 'Person in Project', last_name: 'Petersen', updated_at: 1.second.from_now)
    assert person_not_in_project.projects.empty?
    refute person_in_project.projects.empty?

    get :index, params: { page: 'P' }
    assert_response :success
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item_title  a[href=?]', person_path(person_in_project), text: /#{person_in_project.name}/, count: 1
      assert_select 'div.list_item_title  a[href=?]', person_path(person_not_in_project), text: /#{person_not_in_project.name}/, count: 1
    end

    get :index, params: { page: 'P' }
    assert_response :success
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item_title  a[href=?]', person_path(person_in_project), text: /#{person_in_project.name}/, count: 1
      assert_select 'div.list_item_title  a[href=?]', person_path(person_not_in_project), text: /#{person_not_in_project.name}/, count: 1
    end
  end

  test 'project people through filtered route' do
    assert_routing 'projects/2/people', controller: 'people', action: 'index', project_id: '2'

    person1 = Factory(:person)
    proj = person1.projects.first
    person2 = Factory(:person, group_memberships: [Factory(:group_membership, work_group: proj.work_groups.first)])
    person3 = Factory(:person)
    assert_equal 2, proj.people.count
    refute proj.people.include?(person3)
    get :index, params: { project_id: proj.id }
    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', person_path(person1), text: person1.name
      assert_select 'a[href=?]', person_path(person2), text: person2.name
      assert_select 'a[href=?]', person_path(person3), text: person3.name, count: 0
    end
  end

  test 'filtered by presentation via nested route' do
    assert_routing 'presentations/4/people', controller: 'people', action: 'index', presentation_id: '4'
    person1 = Factory(:person)
    person2 = Factory(:person)
    presentation1 = Factory(:presentation, policy: Factory(:public_policy), contributor: person1)
    presentation2 = Factory(:presentation, policy: Factory(:public_policy), contributor: person2)

    refute_equal presentation1.contributor, presentation2.contributor
    get :index, params: { presentation_id: presentation1.id }

    assert_response :success
    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', person_path(person1), text: person1.name
      assert_select 'a[href=?]', person_path(person2), text: person2.name, count: 0
    end
  end

  test 'filtered by programme via nested route' do
    assert_routing 'programmes/4/people', controller: 'people', action: 'index', programme_id: '4'
    person1 = Factory(:person)
    person2 = Factory(:person)
    prog1 = Factory(:programme, projects: [person1.projects.first])
    prog2 = Factory(:programme, projects: [person2.projects.first])

    get :index, params: { programme_id: prog1.id }
    assert_response :success

    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', person_path(person1), text: person1.name
      assert_select 'a[href=?]', person_path(person2), text: person2.name, count: 0
    end
  end

  test 'should show personal tags according to config' do
    p = Factory(:person)
    get :show, params: { id: p.id }
    assert_response :success
    assert_select 'div#personal_tags', count: 1
    with_config_value :tagging_enabled, false do
      get :show, params: { id: p.id }
      assert_response :success
      assert_select 'div#personal_tags', count: 0
    end
  end

  test 'should show related items' do
    person = Factory(:person)
    project = person.projects.first
    inst = person.institutions.first

    refute_nil project
    refute_nil inst

    get :show, params: { id: person.id }
    assert_response :success

    assert_select 'h2', text: /Related items/i
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item' do
        assert_select 'div.list_item_title' do
          assert_select 'a[href=?]', project_path(project), text: project.title
          assert_select 'a[href=?]', institution_path(inst), text: inst.title
        end
      end
    end
  end

  test 'related investigations should show where person is creator' do
    person = Factory(:person)
    inv1 = Factory(:investigation, contributor: Factory(:person), policy: Factory(:public_policy))
    AssetsCreator.create asset: inv1, creator: person
    inv2 = Factory(:investigation, contributor: person)

    login_as(person)

    get :show, params: { id: person.id }
    assert_response :success
    assert_select 'h2', text: /Related items/i
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item' do
        assert_select 'div.list_item_title' do
          assert_select 'a[href=?]', investigation_path(inv1), text: inv1.title
          assert_select 'a[href=?]', investigation_path(inv2), text: inv2.title
        end
      end
    end
  end

  test 'related studies should show where person is creator' do
    person = Factory(:person)
    study1 = Factory(:study, contributor: Factory(:person), policy: Factory(:public_policy))
    AssetsCreator.create asset: study1, creator: person
    study2 = Factory(:study, contributor: person)

    login_as(person)

    get :show, params: { id: person.id }
    assert_response :success
    assert_select 'h2', text: /Related items/i
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item' do
        assert_select 'div.list_item_title' do
          assert_select 'a[href=?]', study_path(study1), text: study1.title
          assert_select 'a[href=?]', study_path(study2), text: study2.title
        end
      end
    end
  end

  test 'related assays should show where person is creator' do
    person = Factory(:person)
    assay1 = Factory(:assay, contributor: Factory(:person), policy: Factory(:public_policy))
    AssetsCreator.create asset: assay1, creator: person
    assay2 = Factory(:assay, contributor: person)

    login_as(person)

    get :show, params: { id: person.id }
    assert_response :success
    assert_select 'h2', text: /Related items/i
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item' do
        assert_select 'div.list_item_title' do
          assert_select 'a[href=?]', assay_path(assay1), text: assay1.title
          assert_select 'a[href=?]', assay_path(assay2), text: assay2.title
        end
      end
    end
  end


  test 'redirect after destroy' do
    person1 = Factory(:person)
    person2 = Factory(:person)

    @request.env['HTTP_REFERER'] = "/people/#{person1.id}"
    assert_difference('Person.count', -1) do
      delete :destroy, params: { id: person1 }
    end
    assert_redirected_to people_path

    @request.env['HTTP_REFERER'] = '/admin'
    assert_difference('Person.count', -1) do
      delete :destroy, params: { id: person2 }
    end
    assert_redirected_to admin_path
  end

  test 'contact details only visible for programme' do
    person1 = Factory(:person, email: 'fish@email.com', skype_name: 'fish')
    person2 = Factory(:person, email: 'monkey@email.com', skype_name: 'monkey')
    person3 = Factory(:person, email: 'parrot@email.com', skype_name: 'parrot')

    prog1 = Factory :programme, projects: (person1.projects | person2.projects)
    prog2 = Factory :programme, projects: person3.projects

    # check programme assignment
    assert_equal person1.programmes, person2.programmes
    refute_equal person1.programmes, person3.programmes

    login_as(person1)

    # should see for person2
    get :show, params: { id: person2 }
    assert_select 'div#contact_details', count: 1
    assert_select 'div#email', text: /monkey@email.com/, count: 1
    assert_select 'div#skype', text: /monkey/, count: 1

    # should not see for person3 in different programme
    get :show, params: { id: person3 }
    assert_select 'div#contact_details', count: 0
    assert_select 'div#email', text: /parrot@email.com/, count: 0
    assert_select 'div#skype', text: /parrot/, count: 0
  end

  test 'is this you? page for register with matching email' do
    u = Factory(:brand_new_user)
    refute u.person
    p = Factory(:brand_new_person, email: 'jkjkjk@theemail.com')
    login_as(u)
    get :register, params: { email: 'jkjkjk@theemail.com' }
    assert_response :success
    assert_select 'h1', text: 'Is this you?', count: 1
    assert_select 'p.list_item_attribute', text: /#{p.name}/, count: 1
    assert_select 'h1', text: 'New profile', count: 0
  end

  test 'new profile page when matching email matches person already registered' do
    u = Factory(:brand_new_user)
    refute u.person
    p = Factory(:person, email: 'jkjkjk@theemail.com')
    login_as(u)
    get :register, params: { email: 'jkjkjk@theemail.com' }
    assert_response :success
    assert_select 'h1', text: 'Is this you?', count: 0
    assert_select 'h1', text: 'New profile', count: 1
  end

  test "orcid not required when creating another person's profile" do
    login_as(Factory(:admin))

    with_config_value(:orcid_required, true) do
      assert_nothing_raised do
        no_orcid = Factory :brand_new_person, email: 'FISH-sOup1@email.com'
        assert no_orcid.valid?
        assert_empty no_orcid.errors[:orcid]
      end
    end
  end

  test 'my items' do
    me = Factory(:person)

    login_as(me)

    someone_else = Factory(:person)
    data_file = Factory(:data_file, contributor: me, creators: [me])
    model = Factory(:model, contributor: me, creators: [me])
    other_data_file = Factory(:data_file, contributor: someone_else, creators: [someone_else])

    assert_includes me.contributed_items, data_file
    assert_includes me.contributed_items, model
    refute_includes me.contributed_items, other_data_file

    get :items, params: { id: me.id }
    assert_response :success

    project = me.projects.first
    other_project = someone_else.projects.first

    assert_select 'div.list_items_container' do
      assert_select 'div.list_item_title  a[href=?]', project_path(project), text: /#{project.title}/, count: 1
      assert_select 'div.list_item_title  a[href=?]', data_file_path(data_file), text: /#{data_file.title}/, count: 1
      assert_select 'div.list_item_title  a[href=?]', model_path(model), text: /#{model.title}/, count: 1

      assert_select 'div.list_item_title  a[href=?]', data_file_path(other_data_file), text: /#{other_data_file.title}/, count: 0
      assert_select 'div.list_item_title  a[href=?]', project_path(other_project), text: /#{other_project.title}/, count: 0
    end
  end

  test 'my items permissions' do
    person = Factory(:person)
    login_as(person)

    other_person = Factory(:person)
    data_file = Factory(:data_file, contributor: other_person, creators: [other_person], policy: Factory(:public_policy))
    data_file2 = Factory(:data_file, contributor: other_person, creators: [other_person], policy: Factory(:private_policy))

    assert data_file.can_view?(person.user)
    refute data_file2.can_view?(person.user)

    get :items, params: { id: other_person.id }
    assert_response :success

    project = other_person.projects.first

    assert_select 'div.list_items_container' do
      assert_select 'div.list_item_title  a[href=?]', project_path(project), text: /#{project.title}/, count: 1

      assert_select 'div.list_item_title  a[href=?]', data_file_path(data_file), text: /#{data_file.title}/, count: 1
      assert_select 'div.list_item_title  a[href=?]', data_file_path(data_file2), text: /#{data_file2.title}/, count: 0
    end
  end

  test 'my items longer list' do
    # the myitems shows a longer list of 50, rather than the related_items_limit configuration
    person = Factory(:person)
    login_as(person)
    data_files = []
    50.times do
      data_files << Factory(:data_file, contributor: person, creators: [person])
    end

    assert_equal 50, data_files.length

    with_config_value :related_items_limit, 1 do
      get :items, params: { id: person.id }
      assert_response :success
    end

    assert_select 'div.list_items_container' do
      assert_select 'div.list_item_title  a[href=?]', data_file_path(data_files.first), text: /#{data_files.first.title}/, count: 1
      assert_select 'div.list_item_title  a[href=?]', data_file_path(data_files.last), text: /#{data_files.last.title}/, count: 1
    end
  end

  test 'autocomplete' do
    Factory(:brand_new_person, first_name: 'Xavier', last_name: 'Johnson')
    Factory(:brand_new_person, first_name: 'Xavier', last_name: 'Bohnson')
    Factory(:brand_new_person, first_name: 'Charles', last_name: 'Bohnson')
    Factory(:brand_new_person, first_name: 'Jon Bon', last_name: 'Jovi')
    Factory(:brand_new_person, first_name: 'Jon', last_name: 'Bon Jovi')

    get :typeahead, params: { format: :json, query: 'xav' }
    assert_response :success
    res = JSON.parse(response.body)
    assert_equal 2, res.length
    assert_includes res.map { |r| r['name'] }, 'Xavier Johnson'
    assert_includes res.map { |r| r['name'] }, 'Xavier Bohnson'

    get :typeahead, params: { format: :json, query: 'bohn' }
    assert_response :success
    res = JSON.parse(response.body)
    assert_equal 2, res.length
    assert_includes res.map { |r| r['name'] }, 'Charles Bohnson'
    assert_includes res.map { |r| r['name'] }, 'Xavier Bohnson'

    get :typeahead, params: { format: :json, query: 'xavier bohn' }
    assert_response :success
    res = JSON.parse(response.body)
    assert_equal 1, res.length
    assert_includes res.map { |r| r['name'] }, 'Xavier Bohnson'

    get :typeahead, params: { format: :json, query: 'jon bon' }
    assert_response :success
    res = JSON.parse(response.body)
    assert_equal 2, res.length
    assert_equal res.map { |r| r['name'] }.uniq, ['Jon Bon Jovi']
  end

  test 'related samples are checked for authorization' do
    person = Factory(:person)
    other_person = Factory(:person)
    sample1 = Factory(:sample, contributor: other_person, policy: Factory(:public_policy))
    sample2 = Factory(:sample, contributor: other_person, policy: Factory(:private_policy))
    login_as(person)
    assert sample1.can_view?
    refute sample2.can_view?
    other_person.reload
    assert_equal [sample1, sample2].sort, other_person.related_samples.sort

    get :show, params: { id: other_person }

    assert_response :success

    assert_select 'div.list_items_container' do
      # assert_select 'div.list_item' do
      # assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', sample_path(sample1), text: /#{sample1.title}/, count: 1
      assert_select 'a[href=?]', sample_path(sample2), text: /#{sample2.title}/, count: 0
      # end
      # end
    end
  end

  test 'admin should destroy person with project subscriptions' do
    admin = Factory(:admin)
    person = Factory(:person)
    project = person.projects.first
    data_file = Factory(:data_file, projects: [project])

    project_sub = person.project_subscriptions.first
    Factory(:subscription, person: person, subscribable: data_file, project_subscription: project_sub)

    refute data_file.can_delete?(admin.user)
    assert person.can_delete?(admin.user)

    assert_difference('Person.count', -1) do
      assert_difference('ProjectSubscription.count', -1) do
        assert_difference('Subscription.count', -1) do
          delete :destroy, params: { id: person }
        end
      end
    end

    assert_redirected_to people_path
  end

  test 'should show project position on person show page' do
    pos = Factory(:project_position, name: 'Barista')
    project_administrator = Factory(:project_administrator)
    project_administrator.group_memberships.last.project_positions = [pos]
    get :show, params: { id: project_administrator }
    assert_select '#project-positions label', text: /#{pos.name}/, count: 1
  end

  test 'current should show current person' do
    get :current, format: :json

    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal people(:quentin_person).id.to_s, body['data']['id']
  end

  test 'current should return not found if no one logged in' do
    logout

    get :current, format: :json

    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_nil body['data']
  end

  test 'notification params' do
    wg1 = Factory(:work_group)
    wg2 = Factory(:work_group)
    user = Factory(:activated_user)
    assert_nil user.person
    login_as(user)

    post :create, params: { person: { first_name: 'Fred', last_name: 'BBB', email: 'fred.bbb@email.com' },
                            projects: [wg1.project_id, wg2.project_id],
                            institutions: [wg1.institution_id, wg2.institution_id],
                            other_projects: 'Testy',
                            other_institutions: 'Testo' }

    notif_params = @controller.send(:notification_params)
    assert_equal [wg1.project_id, wg2.project_id].sort, notif_params[:projects].map(&:to_i).sort
    assert_equal [wg1.institution_id, wg2.institution_id].sort, notif_params[:institutions].map(&:to_i).sort
    assert_equal 'Testy', notif_params[:other_projects]
    assert_equal 'Testo' ,notif_params[:other_institutions]
  end

  def edit_max_object(person)
    Factory :expertise, value: 'golf', annotatable: person
    Factory :expertise, value: 'fishing', annotatable: person
    Factory :tool, value: 'fishing rod', annotatable: person
    Factory(:event, contributor: person, policy: Factory(:public_policy))
    position = ProjectPosition.find_by_name('PI')
    person.group_memberships.first.project_positions << position
    #person.save
    add_avatar_to_test_object(person)
  end

  def mask_for_admin
    Seek::Roles::Roles.instance.mask_for_role('admin')
  end

  def mask_for_pal
    Seek::Roles::Roles.instance.mask_for_role('pal')
  end

  def role_image(role)
    Seek::ImageFileDictionary.instance.image_filename_for_key(role)
  end
end
