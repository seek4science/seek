require 'test_helper'

class PeopleControllerTest < ActionController::TestCase
  fixtures :people, :users, :projects, :work_groups, :group_memberships, :institutions, :roles

  include AuthenticatedTestHelper
  include ApplicationHelper
  include RdfTestCases

  def setup
    login_as(:quentin)
  end

  def test_title
    get :index
    assert_select 'title', text: 'People', count: 1
  end

  def test_should_get_index
    get :index
    assert_response :success
    refute_nil assigns(:people)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_first_registered_person_is_admin_and_default_project
    Person.delete_all
    Project.delete_all

    project = FactoryBot.create(:work_group).project
    refute_empty project.institutions
    institution = project.institutions.first
    refute_nil(institution)

    assert_equal 0, Person.count, 'There should be no people in the database'
    user = FactoryBot.create(:activated_user)
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
    login_as(FactoryBot.create(:admin))
    assert_difference('Person.count') do
      post :create, params: { person: { first_name: 'test', email: ' hghg@sdfsd.com ' } }
    end
    assert person = assigns(:person)
    assert_equal 'hghg@sdfsd.com', person.email
  end

  def test_second_registered_person_is_not_admin
    Person.delete_all
    person = FactoryBot.create(:brand_new_person, first_name: 'fred', email: 'fred@dddd.com')
    assert_equal 1, Person.count, 'There should be 1 person in the database'
    user = FactoryBot.create(:activated_user)
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

  test 'should_create_person' do

    assert_difference('Person.count') do
      assert_difference('NotifieeInfo.count') do
        post :create, params: { person: { first_name: 'test', email: 'hghg@sdfsd.com' } }
      end
    end

    assert_redirected_to person_path(assigns(:person))
    assert_equal 'T', assigns(:person).first_letter
    refute_nil Person.find(assigns(:person).id).notifiee_info
  end

  test 'activation required after create' do
    FactoryBot.create(:person) # make sure a person is present, first person would otherwise be the admin

    login_as(FactoryBot.create(:brand_new_user))
    with_config_value(:activation_required_enabled,true) do
      with_config_value(:email_enabled, true) do
        assert_difference('Person.count') do
          assert_difference('ActivationEmailMessageLog.count') do
            assert_enqueued_emails(2) do #1 to admin, and 1 email requesting activation
              post :create, params: { person: { first_name: 'test', email: 'hghg@sdfsd.com' } }
            end
          end
        end
      end
    end

    person = assigns(:person)
    assert_redirected_to activation_required_users_path
    refute person.user.active?
    assert_equal 1,ActivationEmailMessageLog.activation_email_logs(person).count
    assert_equal person,ActivationEmailMessageLog.activation_email_logs(person).last.subject
    assert_equal 1,person.activation_email_logs.count
  end

  test 'cannot access select form as registered user, even admin' do
    login_as FactoryBot.create(:admin)
    get :register
    assert_redirected_to(root_path)
    refute_nil flash[:error]
  end

  test 'should reload form for incomplete details' do
    new_user = FactoryBot.create(:brand_new_user)
    assert new_user.person.nil?

    login_as(new_user)

    assert_no_difference('Person.count') do
      post :create, params: { person: { first_name: 'test' } }
    end
    assert_response :success

    assert_select 'div#error_explanation' do
      assert_select 'ul > li', text: "Email can't be blank"
    end
    assert_select 'form#new_person' do
      assert_select 'input#person_first_name[value=?]', 'test'
    end
  end

  def test_should_create_person_with_project
    work_group_id = FactoryBot.create(:work_group).id
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
    refute_nil p.notifiee_info
    assert p.notifiee_info.receive_notifications?
  end

  def test_should_show_person
    get :show, params: { id: people(:quentin_person) }
    assert_response :success
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
    project_admin = FactoryBot.create(:project_administrator)
    unregistered_person = FactoryBot.create(:brand_new_person,
                                  group_memberships: [FactoryBot.create(:group_membership,
                                                              work_group: project_admin.group_memberships.first.work_group)])
    refute (project_admin.projects & unregistered_person.projects).empty?,
           'Project administrator should belong to the same project as the person he is trying to edit'

    login_as(project_admin)

    get :edit, params: { id: unregistered_person.id }
    assert_response :success
  end

  test "project administrator cannot edit registered users' profiles in their project" do
    project_admin = FactoryBot.create(:project_administrator)
    registered_person = FactoryBot.create(:person,
                                group_memberships: [FactoryBot.create(:group_membership,
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
    p = FactoryBot.create(:person)
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
    current_user = FactoryBot.create(:person).user
    login_as(current_user)
    get :show, params: { id: current_user.person }
    assert_select '.box_about_actor p', text: /Login/m
    assert_select '.box_about_actor p', text: /Login.*#{current_user.login}/m
  end

  def test_not_current_user_doesnt_show_login_name
    current_user = FactoryBot.create(:person).user
    other_person = FactoryBot.create(:person)
    login_as(current_user)
    get :show, params: { id: other_person }
    assert_select '.box_about_actor p', text: /Login/m, count: 0
  end

  def test_admin_sees_non_current_user_login_name
    current_user = FactoryBot.create(:admin).user
    other_person = FactoryBot.create(:person)
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
    refute_nil flash[:error]
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

  test 'sort by downloads not available' do
    get :index
    assert_select '#index_sort_order' do
      assert_select 'option', { text: 'Downloads (Descending)', count: 0 }
    end
  end

  test 'sort by views not available' do
    get :index
    assert_select '#index_sort_order' do
      assert_select 'option', { text: 'Views (Descending)', count: 0 }
    end
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
    person = FactoryBot.create(:person)
    # create bunch of permissions on this person
    i = 0
    while i < 10
      FactoryBot.create(:permission, contributor: person, access_type: rand(5))
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

  test 'should have asset housekeeper role on person show page' do
    asset_housekeeper = FactoryBot.create(:asset_housekeeper)
    get :show, params: { id: asset_housekeeper }
    assert_select '#person-roles h3 img[src*=?]', role_image(:asset_housekeeper), count: 1
  end

  test 'should have asset housekeeper icon on people index page' do
    6.times do
      FactoryBot.create(:asset_housekeeper)
    end

    get :index, params: { page: 'all' }

    asset_housekeeper_number = assigns(:people).select(&:is_asset_housekeeper_of_any_project?).count
    assert_select 'img[src*=?]', role_image(:asset_housekeeper), count: asset_housekeeper_number
  end

  test 'should have project administrator role on person show page' do
    project_administrator = FactoryBot.create(:project_administrator)
    get :show, params: { id: project_administrator }
    assert_select '#person-roles h3 img[src*=?]', role_image(:project_administrator), count: 1
  end

  test 'should have project administrator icon on people index page' do
    6.times do
      FactoryBot.create(:project_administrator)
    end

    get :index, params: { page: 'all' }

    project_administrator_count = assigns(:people).select(&:is_project_administrator_of_any_project?).count
    assert_select 'img[src*=?]', role_image(:project_administrator), count: project_administrator_count
  end

  test 'allow project administrator to edit unregistered people inside their projects, even outside their institutions' do
    project_admin = FactoryBot.create(:project_administrator)
    project = project_admin.projects.first
    person = FactoryBot.create(:brand_new_person,
                     group_memberships: [FactoryBot.create(:group_membership,
                                                 work_group: FactoryBot.create(:work_group, project: project))])
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
    login_as(FactoryBot.create(:project_administrator))
    get :new
    assert_response :success
  end

  test 'project administrator can create new profile' do
    login_as(FactoryBot.create(:project_administrator))
    assert_difference('Person.count') do
      post :create, params: { person: { first_name: 'test', email: 'ttt@email.com' } }
    end
    person = assigns(:person)
    refute_nil person
    assert_equal 'test', person.first_name
    assert_equal 'ttt@email.com', person.email
  end

  test 'normal user cannot can view profile creation' do
    login_as(FactoryBot.create(:person))
    get :new
    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test 'normal user cannot create new profile' do
    login_as(FactoryBot.create(:person))
    assert_no_difference('Person.count') do
      post :create, params: { person: { first_name: 'test', email: 'ttt@email.com' } }
    end
    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test 'not allow project administrator to edit people outside their projects' do
    project_admin = FactoryBot.create(:project_administrator)
    a_person = FactoryBot.create(:person)
    refute_includes project_admin.projects, a_person.projects.first, 'they should not be in the same project'
    assert_equal 1, a_person.projects.count, 'should by in only 1 project'

    login_as(project_admin)
    get :edit, params: { id: a_person }

    assert_response :redirect
    refute_nil flash[:error]

    put :update, params: { id: a_person, person: { first_name: 'blabla' } }

    assert_response :redirect
    refute_nil flash[:error]
    a_person.reload
    assert_not_equal 'blabla', a_person.first_name
  end

  test 'project administrator can not edit admin' do
    project_admin = FactoryBot.create(:project_administrator)
    admin = FactoryBot.create(:admin, group_memberships: [FactoryBot.create(:group_membership, work_group: project_admin.group_memberships.first.work_group)])

    login_as(project_admin)
    get :show, params: { id: admin }
    assert_select 'a', text: /Edit Profile/, count: 0

    get :edit, params: { id: admin }

    assert_response :redirect
    refute_nil flash[:error]

    put :update, params: { id: admin, person: { first_name: 'blablba' } }

    assert_response :redirect
    refute_nil flash[:error]

    refute_equal 'blablba', assigns(:person).first_name
  end

  test 'admin can edit other admin' do
    admin = FactoryBot.create(:admin)
    refute_nil admin.user
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

  test 'should show joined date to non admin, and include time for admin' do
    login_as(FactoryBot.create(:person))
    a_person = FactoryBot.create(:person)
    get :show, params: { id: a_person }
    assert_response :success
    assert_select 'p', text: /#{date_as_string(a_person.user.created_at)}/, count: 1
    assert_select 'p', text: /#{date_as_string(a_person.user.created_at, true)}/, count: 0

    login_as(FactoryBot.create(:admin))
    get :show, params: { id: a_person }
    assert_response :success
    assert_select 'p', text: /#{date_as_string(a_person.user.created_at)}/, count: 1
    assert_select 'p', text: /#{date_as_string(a_person.user.created_at, true)}/, count: 1

    logout
    get :show, params: { id: a_person }
    assert_response :success
    assert_select 'p', text: /#{date_as_string(a_person.user.created_at)}/, count: 1
    assert_select 'p', text: /#{date_as_string(a_person.user.created_at, true)}/, count: 0
  end

  test 'should have gatekeeper role on person show page' do
    gatekeeper = FactoryBot.create(:asset_gatekeeper)
    get :show, params: { id: gatekeeper }
    assert_select '#person-roles h3 img[src*=?]', role_image(:asset_gatekeeper), count: 1
  end

  test 'should show all roles on person show page' do
    programme = FactoryBot.create(:programme)
    project = FactoryBot.create(:project)
    person = FactoryBot.create(:person, project: project)

    assert_difference('Role.count', RoleType.all.count) do
      disable_authorization_checks do
        RoleType.for_system.each do |rt|
          person.assign_role(rt.key)
        end
        RoleType.for_projects.each do |rt|
          person.assign_role(rt.key, project)
        end
        RoleType.for_programmes.each do |rt|
          person.assign_role(rt.key, programme)
        end
        person.save
      end
    end

    get :show, params: { id: person }

    assert_select '#person-roles h3', count: RoleType.all.count
    RoleType.all.each do |rt|
      assert_select '#person-roles h3 img[src*=?]', role_image(rt.key), { count: 1 }, "Missing image for #{rt.key}"
    end
    assert_select '#person-roles a[href=?]', project_path(project), count: RoleType.for_projects.count
    assert_select '#person-roles a[href=?]', programme_path(programme), count: RoleType.for_programmes.count
  end

  test 'should have gatekeeper icon on people index page' do
    6.times do
      FactoryBot.create(:asset_gatekeeper)
    end

    get :index, params: { page: 'all' }

    gatekeeper_number = assigns(:people).select(&:is_asset_gatekeeper_of_any_project?).count
    assert_select 'img[src*=?]', role_image(:asset_gatekeeper), count: gatekeeper_number
  end

  test 'unsubscribe to a project should unsubscribe all the items of that project' do
    with_config_value 'email_enabled', true do
      current_person = User.current_user.person
      proj = current_person.projects.first
      sop = FactoryBot.create(:sop, projects: [proj], policy: FactoryBot.create(:public_policy))
      df = FactoryBot.create(:data_file, projects: [proj], policy: FactoryBot.create(:public_policy))

      # subscribe to project
      put :update, params: { id: current_person, receive_notifications: true, person: { project_subscriptions_attributes: { '0' => { project_id: proj.id, frequency: 'weekly', _destroy: '0' } } } }
      assert_redirected_to current_person

      project_subscription = ProjectSubscription.where({project_id:proj.id, person_id:current_person.id}).first
      assert_difference 'Subscription.count', 2 do
        ProjectSubscriptionJob.perform_now(project_subscription)
      end
      assert sop.subscribed?(current_person)
      assert df.subscribed?(current_person)
      assert current_person.receive_notifications?

      assert_enqueued_emails 1 do
        FactoryBot.create(:activity_log, activity_loggable: sop, action: 'update')
        FactoryBot.create(:activity_log, activity_loggable: df, action: 'update')
        PeriodicSubscriptionEmailJob.perform_now('weekly')
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
        FactoryBot.create(:activity_log, activity_loggable: sop, action: 'update')
        FactoryBot.create(:activity_log, activity_loggable: df, action: 'update')
        PeriodicSubscriptionEmailJob.perform_now('weekly')
      end
    end
  end

  test 'should show subscription list to only yourself and admin' do
    a_person = FactoryBot.create(:person)
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
    a_person = FactoryBot.create(:person)
    login_as(FactoryBot.create(:user))
    get :show, params: { id: a_person }
    assert_response :success
    assert_select 'div.panel-heading', text: 'Subscriptions', count: 0

    logout

    get :show, params: { id: a_person }
    assert_response :success
    assert_select 'div.panel-heading', text: 'Subscriptions', count: 0
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
      get :index, params: { view: 'default' }
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
      # Reset the view parameter
      session.delete(:view)
    end
  end

  test 'Condensed views should use a different results_per_page default' do
    with_config_value(:results_per_page_default, 2) do
      with_config_value(:results_per_page_default_condensed, 3) do
        # Load a regular default view, and a condensed view, and check that the number of items in each are different
        get :index, params: { view: 'default' }
        assert_response :success
        assert_equal 2, assigns(:per_page)
        assert_select '.pagination-container li.active', text: '1'
        assert_select 'div.list_item_title', count: 2

        get :index, params: { view: 'condensed' }
        assert_response :success
        assert_equal 3, assigns(:per_page)
        assert_select '.pagination-container li.active', text: '1'
        assert_select '.list_items_container .collapse', count: 3


        get :index, params: { view: 'table' }
        assert_response :success
        assert_equal 3, assigns(:per_page)
        assert_select '.pagination-container li.active', text: '1'
        assert_select '.list_items_container tbody tr', count: 3
      end
      # Reset the view parameter
      session.delete(:view)
    end
  end

  test 'people not in projects should be shown in index' do
    person_not_in_project = FactoryBot.create(:brand_new_person, first_name: 'Person Not In Project', last_name: 'Petersen', updated_at: 1.second.from_now)
    person_in_project = FactoryBot.create(:person, first_name: 'Person in Project', last_name: 'Petersen', updated_at: 1.second.from_now)
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

    person1 = FactoryBot.create(:person)
    proj = person1.projects.first
    person2 = FactoryBot.create(:person, group_memberships: [FactoryBot.create(:group_membership, work_group: proj.work_groups.first)])
    person3 = FactoryBot.create(:person)
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
    person1 = FactoryBot.create(:person)
    person2 = FactoryBot.create(:person)
    presentation1 = FactoryBot.create(:presentation, policy: FactoryBot.create(:public_policy), contributor: person1)
    presentation2 = FactoryBot.create(:presentation, policy: FactoryBot.create(:public_policy), contributor: person2)

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
    person1 = FactoryBot.create(:person)
    person2 = FactoryBot.create(:person)
    prog1 = FactoryBot.create(:programme, projects: [person1.projects.first])
    prog2 = FactoryBot.create(:programme, projects: [person2.projects.first])

    get :index, params: { programme_id: prog1.id }
    assert_response :success

    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', person_path(person1), text: person1.name
      assert_select 'a[href=?]', person_path(person2), text: person2.name, count: 0
    end
  end

  test 'should show personal tags according to config' do
    p = FactoryBot.create(:person)
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
    person = FactoryBot.create(:person)
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

  test 'should show empty programme as related item if programme administrator' do
    person1 = FactoryBot.create(:programme_administrator_not_in_project)
    prog1 = FactoryBot.create(:min_programme, programme_administrators: [person1])

    assert person1.projects.empty?

    get :show, params: { id: person1.id }
    assert_response :success

    assert_select 'h2', text: /Related items/i
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item' do
        assert_select 'div.list_item_title' do
          assert_select 'a[href=?]', programme_path(prog1), text: prog1.title
        end
      end
    end
  end

  test 'related investigations should show where person is creator' do
    person = FactoryBot.create(:person)
    inv1 = FactoryBot.create(:investigation, contributor: FactoryBot.create(:person), policy: FactoryBot.create(:public_policy))
    AssetsCreator.create asset: inv1, creator: person
    inv2 = FactoryBot.create(:investigation, contributor: person)

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
    person = FactoryBot.create(:person)
    study1 = FactoryBot.create(:study, contributor: FactoryBot.create(:person), policy: FactoryBot.create(:public_policy))
    AssetsCreator.create asset: study1, creator: person
    study2 = FactoryBot.create(:study, contributor: person)

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
    person = FactoryBot.create(:person)
    assay1 = FactoryBot.create(:assay, contributor: FactoryBot.create(:person), policy: FactoryBot.create(:public_policy))
    AssetsCreator.create asset: assay1, creator: person
    assay2 = FactoryBot.create(:assay, contributor: person)

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

  test 'related sample_types should show where person is creator' do
    person1 = FactoryBot.create(:person)
    person2 = FactoryBot.create(:person)
    st1 = FactoryBot.create(:simple_sample_type, contributor: person1, creators: [person1])
    st2 = FactoryBot.create(:simple_sample_type, contributor: person1, creators: [person2])
    st3 = FactoryBot.create(:simple_sample_type, contributor: person2, creators: [person1])

    login_as(person1)
    assert st1.can_view?
    assert st2.can_view?
    assert st3.can_view?
    get :show, params: { id: person1.id }
    assert_response :success
    assert_select 'h2', text: /Related items/i
    assert_select 'div#sampletypes'
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item' do
        assert_select 'div.list_item_title' do
          assert_select 'a[href=?]', sample_type_path(st1), text: st1.title
          assert_select 'a[href=?]', sample_type_path(st2), text: st2.title
          assert_select 'a[href=?]', sample_type_path(st3), text: st3.title
        end
      end
    end
  end

  test 'redirect after destroy' do
    person1 = FactoryBot.create(:person)
    person2 = FactoryBot.create(:person)

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
    person1 = FactoryBot.create(:person, email: 'fish@email.com', skype_name: 'fish')
    person2 = FactoryBot.create(:person, email: 'monkey@email.com', skype_name: 'monkey')
    person3 = FactoryBot.create(:person, email: 'parrot@email.com', skype_name: 'parrot')

    prog1 = FactoryBot.create :programme, projects: (person1.projects | person2.projects)
    prog2 = FactoryBot.create :programme, projects: person3.projects

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
    u = FactoryBot.create(:brand_new_user)
    refute u.person
    p = FactoryBot.create(:brand_new_person, email: 'jkjkjk@theemail.com')
    login_as(u)
    get :register, params: { email: 'jkjkjk@theemail.com' }
    assert_response :success
    assert_select 'h1', text: 'Is this you?', count: 1
    assert_select 'p.list_item_attribute', text: /#{p.name}/, count: 1
    assert_select 'h1', text: 'New profile', count: 0
  end

  test 'new profile page when matching email matches person already registered' do
    u = FactoryBot.create(:brand_new_user)
    refute u.person
    p = FactoryBot.create(:person, email: 'jkjkjk@theemail.com')
    login_as(u)
    get :register, params: { email: 'jkjkjk@theemail.com' }
    assert_response :success
    assert_select 'h1', text: 'Is this you?', count: 0
    assert_select 'h1', text: 'New profile', count: 1
  end

  test "orcid not required when creating another person's profile" do
    login_as(FactoryBot.create(:admin))

    with_config_value(:orcid_required, true) do
      assert_nothing_raised do
        no_orcid = FactoryBot.create :brand_new_person, email: 'FISH-sOup1@email.com'
        assert no_orcid.valid?
        assert_empty no_orcid.errors[:orcid]
      end
    end
  end

  test 'my items' do
    me = FactoryBot.create(:person)

    login_as(me)

    someone_else = FactoryBot.create(:person)
    data_file = FactoryBot.create(:data_file, contributor: me, creators: [me])
    model = FactoryBot.create(:model, contributor: me, creators: [me])
    other_data_file = FactoryBot.create(:data_file, contributor: someone_else, creators: [someone_else])

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
    person = FactoryBot.create(:person)
    login_as(person)

    other_person = FactoryBot.create(:person)
    data_file = FactoryBot.create(:data_file, contributor: other_person, creators: [other_person], policy: FactoryBot.create(:public_policy))
    data_file2 = FactoryBot.create(:data_file, contributor: other_person, creators: [other_person], policy: FactoryBot.create(:private_policy))

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
    person = FactoryBot.create(:person)
    login_as(person)
    data_files = []
    50.times do
      data_files << FactoryBot.create(:data_file, contributor: person, creators: [person])
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

  test 'typeahead autocomplete' do
    FactoryBot.create(:brand_new_person, first_name: 'Xavier', last_name: 'Johnson')
    FactoryBot.create(:brand_new_person, first_name: 'Xavier', last_name: 'Bohnson')
    FactoryBot.create(:brand_new_person, first_name: 'Charles', last_name: 'Bohnson')
    FactoryBot.create(:brand_new_person, first_name: 'Jon Bon', last_name: 'Jovi')
    FactoryBot.create(:brand_new_person, first_name: 'Jon', last_name: 'Bon Jovi')

    get :typeahead, params: { format: :json, q: 'xav' }
    assert_response :success
    res = JSON.parse(response.body)['results']
    assert_equal 2, res.length
    assert_includes res.map { |r| r['text'] }, 'Xavier Johnson'
    assert_includes res.map { |r| r['text'] }, 'Xavier Bohnson'

    get :typeahead, params: { format: :json, q: 'bohn' }
    assert_response :success
    res = JSON.parse(response.body)['results']
    assert_equal 2, res.length
    assert_includes res.map { |r| r['text'] }, 'Charles Bohnson'
    assert_includes res.map { |r| r['text'] }, 'Xavier Bohnson'

    get :typeahead, params: { format: :json, q: 'xavier bohn' }
    assert_response :success
    res = JSON.parse(response.body)['results']
    assert_equal 1, res.length
    assert_includes res.map { |r| r['text'] }, 'Xavier Bohnson'

    get :typeahead, params: { format: :json, q: 'jon bon' }
    assert_response :success
    res = JSON.parse(response.body)['results']
    assert_equal 2, res.length
    assert_equal res.map { |r| r['text'] }.uniq, ['Jon Bon Jovi']
  end

  test 'related samples are checked for authorization' do
    person = FactoryBot.create(:person)
    other_person = FactoryBot.create(:person)
    sample1 = FactoryBot.create(:sample, contributor: other_person, policy: FactoryBot.create(:public_policy))
    sample2 = FactoryBot.create(:sample, contributor: other_person, policy: FactoryBot.create(:private_policy))
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
    admin = FactoryBot.create(:admin)
    person = FactoryBot.create(:person)
    project = person.projects.first
    data_file = FactoryBot.create(:data_file, projects: [project])

    project_sub = person.project_subscriptions.first
    FactoryBot.create(:subscription, person: person, subscribable: data_file, project_subscription: project_sub)

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
    wg1 = FactoryBot.create(:work_group)
    wg2 = FactoryBot.create(:work_group)
    user = FactoryBot.create(:activated_user)
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

  test 'result view selection via params' do
    with_config_value(:results_per_page, { 'people' => 3 }) do
      get :index, params: { view: 'table' }
      assert_response :success
      assert_select '.list_items_container tbody tr', count: 3
    end
    # no view param will resort to the last used one
    with_config_value(:results_per_page, { 'people' => 3 }) do
      get :index
      assert_response :success
      assert_select '.list_items_container tbody tr', count: 3
    end
    with_config_value(:results_per_page, { 'people' => 3 }) do
      get :index, params: { view: 'condensed' }
      assert_response :success
      assert_select '.list_items_container .collapse', count: 3
    end
    # Reset the view parameter
    session.delete(:view)
  end

  test 'table view column selection' do
    # Title is always added, and there is an extra header for dropdown selection
    with_config_value(:results_per_page, { 'people' => 3 }) do
      get :index, params: { view: 'table',table_cols:'created_at,first_name,last_name,description,email' }
      assert_response :success
      assert_select '.list_items_container #resource-table-view thead th', count: 5 #only title, first_name, last_name, description allowed (plus th for options)
    end
    # When no columns are specified, resort to default, so it's never empty
    with_config_value(:results_per_page, { 'people' => 3 }) do
      get :index, params: { view: 'table',table_cols:'' }
      assert_response :success
      assert_select '.list_items_container #resource-table-view thead th',  minimum: 3
    end
    # Reset the view parameter
    session.delete(:view)
  end

  test 'admin can see user login through API' do
    login_as(FactoryBot.create(:admin))

    get :show, format: :json, params: { id: FactoryBot.create(:user, login: 'dave1234').person }

    assert_response :success
    h = JSON.parse(response.body)
    assert_equal 'dave1234', h['data']['attributes']['login']
  end

  test 'admin cannot see user login through API if no registered person' do
    login_as(FactoryBot.create(:admin))

    get :show, format: :json, params: { id: FactoryBot.create(:brand_new_person) }

    assert_response :success
    h = JSON.parse(response.body)
    refute h['data']['attributes']['login'].present?
  end

  test 'non-admin cannot see user login through API' do
    login_as(FactoryBot.create(:person))

    get :show, format: :json, params: { id: FactoryBot.create(:user, login: 'dave1234').person }

    assert_response :success
    h = JSON.parse(response.body)
    refute h['data']['attributes'].key?('login')
  end

  def role_image(role)
    Seek::ImageFileDictionary.instance.image_filename_for_key(role)
  end
end
