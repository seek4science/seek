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
    @object = Factory(:person)
  end

  def test_title
    get :index
    assert_select 'title', text: /The Sysmo SEEK People.*/, count: 1
  end

  def test_xml_for_person_with_tools_and_expertise
    p = Factory :person
    Factory :expertise, value: 'golf', annotatable: p
    Factory :expertise, value: 'fishing', annotatable: p
    Factory :tool, value: 'fishing rod', annotatable: p

    test_get_rest_api_xml p

    doc = LibXML::XML::Document.string(@response.body)
    doc.root.namespaces.default_prefix = 's'
    assert_equal 2, doc.find("//s:tags/s:tag[@context='expertise']").count
    assert_equal 1, doc.find("//s:tags/s:tag[@context='tool']").count
    assert_equal 'fishing rod', doc.find("//s:tags/s:tag[@context='tool']").first.content
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
        post :create, person: { first_name: 'test', email: 'hghg@sdfsd.com' }
      end
    end
    assert assigns(:person)
    person = Person.find(assigns(:person).id)
    assert person.is_admin?
    assert person.only_first_admin_person?
    assert_equal [project],person.projects
    assert_equal [institution],person.institutions
    assert_redirected_to registration_form_admin_path(during_setup: 'true')
  end

  def test_second_registered_person_is_not_admin
    Person.delete_all
    person = Person.new(first_name: 'fred', email: 'fred@dddd.com')
    person.save!
    assert_equal 1, Person.count, 'There should be 1 person in the database'
    user = Factory(:activated_user)
    login_as user
    assert_difference('Person.count') do
      assert_difference('NotifieeInfo.count') do
        post :create, person: { first_name: 'test', email: 'hghg@sdfsd.com' }
      end
    end
    assert assigns(:person)
    person = Person.find(assigns(:person).id)
    assert !person.is_admin?
    assert !person.only_first_admin_person?
    assert_redirected_to person_path(person)
  end

  def test_should_create_person
    assert_difference('Person.count') do
      assert_difference('NotifieeInfo.count') do
        post :create, person: { first_name: 'test', email: 'hghg@sdfsd.com' }
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
      post :create, person: { first_name: 'test' }
    end
    assert_response :success

    assert_select 'div#errorExplanation' do
      assert_select 'ul > li', text: 'Email can&#x27;t be blank'
    end
    assert_select 'form#new_person' do
      assert_select 'input#person_first_name[value=?]', 'test'
    end
  end

  def test_should_create_person_with_project
    work_group_id = Factory(:work_group).id
    assert_difference('Person.count') do
      assert_difference('NotifieeInfo.count') do
        post :create, person: { first_name: 'test', email: 'hghg@sdfsd.com' }
      end
    end

    assert_redirected_to person_path(assigns(:person))
    assert_equal 'T', assigns(:person).first_letter

    put :administer_update, id: assigns(:person), person: { work_group_ids: [work_group_id] }

    assert_redirected_to person_path(assigns(:person))
    assert_equal [work_group_id], assigns(:person).work_group_ids
    assert_not_nil Person.find(assigns(:person).id).notifiee_info
  end

  def test_created_person_should_receive_notifications
    post :create, person: { first_name: 'test', email: 'hghg@sdfsd.com' }
    p = assigns(:person)
    assert_not_nil p.notifiee_info
    assert p.notifiee_info.receive_notifications?
  end

  test 'non_admin_should_not_create_pal' do

    login_as(Factory(:person))
    person = Factory(:person)


    put :administer_update, id: person, person: { roles_mask: mask_for_pal }
    assert_redirected_to :root

    p = assigns(:person)

    assert !p.is_pal_of_any_project?
    assert !Person.find(p.id).is_pal_of_any_project?
  end

  def test_should_show_person
    get :show, id: people(:quentin_person)
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
    get :edit, id: people(:quentin_person)
    assert_response :success
  end

  def test_non_admin_cant_edit_someone_else
    login_as(:fred)
    get :edit, id: people(:aaron_person)
    assert_redirected_to people(:aaron_person)
  end

  test "project administrator can edit userless-profiles in their project" do
    project_admin = Factory(:project_administrator)
    unregistered_person = Factory(:brand_new_person,
                           group_memberships: [Factory(:group_membership,
                                                       work_group: project_admin.group_memberships.first.work_group)])
    assert !(project_admin.projects & unregistered_person.projects).empty?,
           'Project administrator should belong to the same project as the person he is trying to edit'

    login_as(project_admin)

    get :edit, id: unregistered_person.id
    assert_response :success
  end

  test "project administrator cannot edit registered users' profiles in their project" do
    project_admin = Factory(:project_administrator)
    registered_person = Factory(:person,
                           group_memberships: [Factory(:group_membership,
                                                       work_group: project_admin.group_memberships.first.work_group)])
    assert !(project_admin.projects & registered_person.projects).empty?,
           'Project administrator should belong to the same project as the person he is trying to edit'

    login_as(project_admin)

    get :edit, id: registered_person.id
    assert_response :redirect
    assert_not_empty flash[:error]
  end

  def test_admin_can_edit_others
    get :edit, id: people(:aaron_person)
    assert_response :success
  end

  def test_change_notification_settings
    p = Factory(:person)
    assert p.notifiee_info.receive_notifications?, 'should receive notifications by default in fixtures'

    put :update, id: p.id, person: { id: p.id }
    assert !Person.find(p.id).notifiee_info.receive_notifications?

    put :update, id: p.id, person: { id: p.id }, receive_notifications: true
    assert Person.find(p.id).notifiee_info.receive_notifications?
  end

  test "admin cannot set roles_mask" do
    login_as(Factory(:admin))
    p = Factory(:person)
    assert !p.is_admin?
    put :administer_update, id: p.id, person: { id: p.id, roles_mask: mask_for_admin }
    assert_redirected_to person_path(p)
    assert_nil flash[:error]
    refute assigns(:person).is_admin?
  end

  test "project admin cannot set roles_mask" do
    p = Factory(:project_administrator)
    login_as(p)
    person = Factory(:person)
    person.add_to_project_and_institution(p.projects.first,p.institutions.first)
    refute person.is_admin?
    put :administer_update, id: person.id, person: { id: person.id, roles_mask: mask_for_admin }
    assert_redirected_to person_path(person)
    assert_nil flash[:error]
    refute assigns(:person).is_admin?
  end



  def test_admin_can_set_pal_flag
    p = Factory(:person_in_multiple_projects)
    project = p.projects.first
    project2 = p.projects[1]
    project3 = p.projects[2]
    assert !p.is_pal_of_any_project?
    put :administer_update, id: p.id, person: { email: 'ssfdsd@sdfsdf.com' }, roles: { pal: [project.id, project2.id] }
    assert_redirected_to person_path(p)
    assert_nil flash[:error]
    p.reload
    assert p.is_pal?(project)
    assert p.is_pal?(project2)
    assert !p.is_pal?(project3)
  end

  def test_non_admin_cant_set_pal_flag
    login_as(:aaron)
    p = Factory(:person)
    assert !p.is_pal?(p.projects.first)
    put :administer_update, id: p.id, person: { email: 'ssfdsd@sdfsdf.com' }, roles: { pal: [p.projects.first.id] }
    p.reload
    assert !p.is_pal?(p.projects.first)
  end

  def test_cant_set_yourself_to_pal
    me = Factory(:person)
    login_as(me)

    assert !me.is_pal?(me.projects.first)
    put :administer_update, id: me.id, person: { email: 'ssfdsd@sdfsdf.com' }, roles: { pal: [me.projects.first.id] }
    me.reload
    assert !me.is_pal?(me.projects.first)
  end

  def test_cant_set_yourself_to_admin
    login_as(:aaron)
    p = people(:aaron_person)
    assert !p.is_admin?
    put :administer_update, id: p.id, person: { id: p.id, roles_mask: mask_for_admin, email: 'ssfdsd@sdfsdf.com' }
    p.reload
    assert !p.is_admin?
  end

  def test_can_edit_person_and_user_id_different
    # where a user_id for a person are not the same
    login_as(:fred)
    get :edit, id: people(:fred)
    assert_response :success
  end

  def test_current_user_shows_seek_id
    login_as(:quentin)
    get :show, id: people(:quentin_person)
    assert_select '.box_about_actor p', text: /Seek ID: /m
    assert_select '.box_about_actor p', text: /Seek ID: .*#{people(:quentin_person).id}/m, count: 1
  end

  def test_not_current_user_doesnt_show_seek_id
    get :show, id: people(:aaron_person)
    assert_select '.box_about_actor p', text: /Seek ID :/, count: 0
  end

  def test_current_user_shows_login_name
    current_user = Factory(:person).user
    login_as(current_user)
    get :show, id: current_user.person
    assert_select '.box_about_actor p', text: /Login/m
    assert_select '.box_about_actor p', text: /Login.*#{current_user.login}/m
  end

  def test_not_current_user_doesnt_show_login_name
    current_user = Factory(:person).user
    other_person = Factory(:person)
    login_as(current_user)
    get :show, id: other_person
    assert_select '.box_about_actor p', text: /Login/m, count: 0
  end

  def test_admin_sees_non_current_user_login_name
    current_user = Factory(:admin).user
    other_person = Factory(:person)
    login_as(current_user)
    get :show, id: other_person
    assert_select '.box_about_actor p', text: /Login/m
    assert_select '.box_about_actor p', text: /Login.*#{other_person.user.login}/m
  end

  def test_should_update_person
    put :update, id: people(:quentin_person), person: {}
    assert_redirected_to person_path(assigns(:person))
  end

  def test_should_not_update_somebody_else_if_not_admin
    login_as(:aaron)
    quentin = people(:quentin_person)
    put :update, id: people(:quentin_person), person: { email: 'kkkkk@kkkkk.com' }
    assert_not_nil flash[:error]
    quentin.reload
    assert_equal 'quentin@email.com', quentin.email
  end

  def test_should_destroy_person
    assert_difference('Person.count', -1) do
      delete :destroy, id: people(:quentin_person)
    end

    assert_redirected_to people_path
  end

  def test_should_add_nofollow_to_links_in_show_page
    get :show, id: people(:person_with_links_in_description)
    assert_select 'div#description' do
      assert_select 'a[rel=nofollow]'
    end
  end

  test 'filtering by project' do
    project = projects(:sysmo_project)
    get :index, filter: { project: project.id }
    assert_response :success
  end

  test 'finding by role' do
    p1 = Factory(:pal)
    p2 = Factory(:person)
    get :index, project_position_id: ProjectPosition.pal_position.id
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
    assert !person.can_manage?

    logout
    assert !person.can_manage?
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
    permissions = Permission.find(:all, conditions: ['contributor_type =? and contributor_id=?', 'Person', person.try(:id)])
    assert_equal 10, permissions.count

    assert_difference('Person.count', -1) do
      delete :destroy, id: person
    end

    permissions = Permission.find(:all, conditions: ['contributor_type =? and contributor_id=?', 'Person', person.try(:id)])
    assert_equal 0, permissions.count
  end

  test 'should set the manage right on pi before deleting the person' do
    login_as(:quentin)

    project = Factory(:project)
    work_group = Factory(:work_group, project: project)
    person = Factory(:person_in_project, group_memberships: [Factory(:group_membership, work_group: work_group)])
    user = Factory(:user, person: person)
    # create a datafile that this person is the contributor
    data_file = Factory(:data_file, contributor: user, project_ids: [project.id])
    # create pi
    position = ProjectPosition.find_by_name('PI')
    pi = Factory(:person_in_project, group_memberships: [Factory(:group_membership, work_group: work_group)])
    pi.group_memberships.first.project_positions << position
    pi.save
    assert_equal pi, project.pis.first

    assert_difference('Person.count', -1) do
      delete :destroy, id: person
    end

    permissions_on_person = Permission.find(:all, conditions: ['contributor_type =? and contributor_id=?', 'Person', person.try(:id)])
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
    data_file = Factory(:data_file, contributor: user, project_ids: [project.id])
    # create pal
    position = ProjectPosition.find_by_name('Sysmo-DB Pal')
    pal = Factory(:person_in_project, group_memberships: [Factory(:group_membership, work_group: work_group)])
    pal.group_memberships.first.project_positions << position
    pal.is_pal = true, project
    pal.save
    assert_equal pal, project.pals.first
    assert_equal 0, project.pis.count

    assert_difference('Person.count', -1) do
      delete :destroy, id: person
    end

    permissions_on_person = Permission.find(:all, conditions: ['contributor_type =? and contributor_id=?', 'Person', person.try(:id)])
    assert_equal 0, permissions_on_person.count

    permissions = data_file.policy.permissions

    assert_equal 1, permissions.count
    assert_equal pal.id, permissions.first.contributor_id
    assert_equal Policy::MANAGING, permissions.first.access_type
  end

  test 'set pal role for a person together with workgroup' do
    work_group = Factory(:work_group)
    assert_difference('Person.count') do
      assert_difference('NotifieeInfo.count') do
        post :create, person: { first_name: 'test', email: 'hghg@sdfsd.com' }
      end
    end
    person = assigns(:person)
    project = work_group.project
    put :administer_update, id: person, person: { work_group_ids: [work_group.id] }, roles: { pal: [project.id] }

    person = assigns(:person)
    assert_not_nil person
    assert person.is_pal?(project)
  end

  test 'set project_administrator role for a person together with workgroup' do
    work_group = Factory(:work_group)
    assert_difference('Person.count') do
      assert_difference('NotifieeInfo.count') do
        post :create, person: { first_name: 'test', email: 'hghg@sdfsd.com' }
      end
    end

    person = assigns(:person)
    project = work_group.project
    put :administer_update, id: person, person: { work_group_ids: [work_group.id] }, roles: { project_administrator: [project.id] }
    person = assigns(:person)
    assert_not_nil person
    assert person.is_project_administrator?(project)
  end

  test 'update roles for a person' do
    person = Factory(:pal)
    project = person.projects.first
    assert_not_nil person
    assert person.is_pal?(project)

    put :administer_update, id: person.id, person: { id: person.id }, roles: { project_administrator: [project.id] }

    person = assigns(:person)
    person.reload
    assert_not_nil person
    assert person.is_project_administrator?(project)
    refute person.is_pal?(project)
  end

  test 'assign somebody to multiple roles and different projects' do
    person = Factory :person_in_multiple_projects
    proj1 = person.projects[0]
    proj2 = person.projects[1]
    assert !person.is_asset_housekeeper?(proj1)
    assert !person.is_project_administrator?(proj2)

    put :administer_update, id: person.id, person: { id: person.id }, roles: { project_administrator: [proj2.id], asset_housekeeper: [proj1.id] }

    person = assigns(:person)
    assert person.is_asset_housekeeper?(proj1)
    assert person.is_project_administrator?(proj2)
  end

  test 'remove somebody from a role' do
    person = Factory(:asset_housekeeper)
    project = person.projects.first

    assert person.is_asset_housekeeper?(project)

    put :administer_update, id: person.id, person: { id: person.id }, roles: {}

    person = assigns(:person)
    assert !person.is_asset_housekeeper?(project)
  end

  test "cannot add a role for a project the person doesn't belong to" do
    person = Factory(:person)
    project = Factory(:project)

    assert !person.is_asset_housekeeper?(project)

    put :administer_update, id: person.id, person: { id: person.id }, roles: { asset_housekeeper: [project.id] }

    person = assigns(:person)
    assert !person.is_asset_housekeeper?(project)
  end

  test 'update roles for yourself, but keep the admin role' do
    person = Factory(:admin)
    login_as(person)
    assert person.is_admin?
    assert_equal ['admin'], person.roles

    project = person.projects.first
    assert_not_nil project

    put :administer_update, id: person.id, person: {}, roles: { project_administrator: [project.id] }

    person = assigns(:person)

    assert_not_nil person
    assert person.is_project_administrator?(project)
    assert person.is_admin?
    assert_equal %w(admin project_administrator), person.roles.sort
  end

  test 'set the asset housekeeper role for a person with workgroup' do
    work_group = Factory(:work_group)
    assert_difference('Person.count') do
      assert_difference('NotifieeInfo.count') do
        post :create, person: { first_name: 'assert housekeper', email: 'asset_housekeeper@sdfsd.com' }
      end
    end
    person = assigns(:person)
    project = work_group.project
    put :administer_update, id: person, person: { work_group_ids: [work_group.id] }, roles: { asset_housekeeper: [project.id] }
    person = assigns(:person)

    assert_not_nil person
    assert person.is_asset_housekeeper?(project)
  end

  test 'admin should see the section of assigning roles to a person' do
    person = Factory(:person)
    get :admin, id: person
    assert_select 'select#_roles_asset_housekeeper', count: 1
    assert_select 'select#_roles_project_administrator', count: 1
    assert_select 'select#_roles_asset_gatekeeper', count: 1
  end

  test 'non-admin should not see the section of assigning roles to a person' do
    login_as(:aaron)
    person = Factory(:person)
    get :admin, id: person
    assert_select 'select#_roles_asset_housekeeper', count: 0
    assert_select 'select#_roles_project_administrator', count: 0
    assert_select 'select#_roles_asset_gatekeeper', count: 0
  end

  test 'project_administrator should see the section assigning roles for administered project' do
    project_admin = Factory(:project_administrator)
    login_as(project_admin)
    project = project_admin.projects.first
    institution = project_admin.institutions.first

    managed_person = Factory(:person)
    managed_person.add_to_project_and_institution(project,institution)
    get :admin, id:managed_person.id
    assert_response :success
    assert_select 'select#_roles_asset_housekeeper', count: 1
    assert_select 'select#_roles_project_administrator', count: 1
    assert_select 'select#_roles_asset_gatekeeper', count: 1

    non_managed_person = Factory(:person)
    get :admin, id:non_managed_person.id
    assert_response :success
    assert_select 'select#_roles_asset_housekeeper', count: 0
    assert_select 'select#_roles_project_administrator', count: 0
    assert_select 'select#_roles_asset_gatekeeper', count: 0

  end

  def test_project_administrator_can_administer_others_in_the_same_project
    pm = Factory(:project_administrator)
    other_person = Factory(:person, group_memberships: [Factory(:group_membership, work_group: pm.group_memberships.first.work_group)])
    assert !(pm.projects & other_person.projects).empty?, 'Project administrator should belong to the same project he is trying to admin'
    login_as(pm)
    get :admin, id: other_person.id
    assert_response :success
  end

  def test_project_administrator_can_administer_others_in_different_project
    pm = Factory(:project_administrator)
    other_person = Factory(:person)
    assert (pm.projects & other_person.projects).empty?, 'Project administrator should not belong to the same project as the person he is trying to admin'
    login_as(pm)
    get :admin, id: other_person.id
    assert_response :success
  end

  def test_admin_can_administer_others
    login_as(Factory(:admin))
    get :admin, id: Factory(:person)
    assert_response :success
  end

  test 'non-admin can not administer others' do
    login_as(Factory(:person))
    get :admin, id: Factory(:person)
    assert_redirected_to :root
  end

  test 'can not administer yourself' do
    person = Factory(:person)
    login_as(person)
    get :admin, id: person.id
    assert_redirected_to :root
  end

  test 'should have asset housekeeper icon on person show page' do
    asset_housekeeper = Factory(:asset_housekeeper)
    get :show, id: asset_housekeeper
    assert_select 'img[src*=?]', /medal_bronze_3.png/, count: 1
  end

  test 'should have asset housekeeper icon on people index page' do
    (0..5).each do
      Factory(:asset_housekeeper)
    end
    get :index
    asset_housekeeper_number = assigns(:people).select(&:is_asset_housekeeper_of_any_project?).count
    assert_select 'img[src*=?]', /medal_bronze_3/, count: asset_housekeeper_number
  end

  test 'should have project administrator icon on person show page' do
    project_administrator = Factory(:project_administrator)
    get :show, id: project_administrator
    assert_select 'img[src*=?]', /medal_gold_1.png/, count: 1
  end

  test 'should have project administrator icon on people index page' do
    (0..5).each do
      Factory(:project_administrator)
    end

    get :index

    project_administrator_count = assigns(:people).select(&:is_project_administrator_of_any_project?).count
    assert_select 'img[src*=?]', /medal_gold_1.png/, count: project_administrator_count
  end

  test 'project administrator can only see projects he can manage to assign to person' do
    project_admin = Factory(:person_in_multiple_projects)
    managed_project = project_admin.projects.first
    not_managed_project = project_admin.projects.last
    project_admin.is_project_administrator = true, managed_project
    project_admin.save!

    assert project_admin.is_project_administrator_of_any_project?
    assert managed_project.can_be_administered_by?(project_admin)
    refute not_managed_project.can_be_administered_by?(project_admin)

    subject = Factory(:person)
    assert subject.can_be_administered_by?(project_admin)
    refute project_admin.user.nil?
    login_as project_admin

    get :admin, id: subject
    assert_response :success

    assert_select '#work_groups' do
      wg = managed_project.work_groups.first
      assert_select 'h4', text: managed_project.title, count: 1
      assert_select "input[type=checkbox]#workgroup_#{wg.id}", count: 1
      assert_select "input[type=checkbox][disabled='disabled']#workgroup_#{wg.id}", count: 0

      wg = not_managed_project.work_groups.first
      assert_select "input[type=checkbox]#workgroup_#{wg.id}", count: 0
      assert_select 'div.wg_project', text: not_managed_project.title, count: 0
    end
  end

  test 'when project administrator admins a person - should show their existing project he cant manage as disabled' do
    project_admin = Factory(:project_administrator)
    person = Factory(:person)
    refute_empty person.projects

    existing_project = person.projects.first
    existing_wg = existing_project.work_groups.first
    login_as project_admin
    get :admin, id: person
    assert_response :success
    assert_select '#work_groups' do
      assert_select 'h4', text: existing_project.title, count: 1
      assert_select "input[type=checkbox][disabled='disabled']#workgroup_#{existing_wg.id}", count: 1
    end
  end

  test 'when administering a persons projects, should not remove the workgroup you cannot administer' do
    project_admin = Factory(:project_administrator)
    person = Factory(:person)
    refute_empty person.projects

    refute project_admin.is_project_administrator?(person.projects.first)
    assert project_admin.is_project_administrator?(project_admin.projects.first)

    existing_wg = person.projects.first.work_groups.first
    project_admin_wg = project_admin.projects.first.work_groups.first

    refute_nil project_admin_wg
    login_as project_admin
    put :administer_update, id: person.id, person: { work_group_ids: [project_admin_wg.id, existing_wg.id] }
    assert_redirected_to person_path(assigns(:person))
    person.reload
    assert_include person.work_groups, project_admin_wg
    assert_include person.work_groups, existing_wg
  end

  test 'not allow project administrator assign people into their projects they do not administer' do
    project_admin = Factory(:person_in_multiple_projects)
    managed_project = project_admin.projects.first
    not_managed_project = project_admin.projects.last
    project_admin.is_project_administrator = true, managed_project
    project_admin.save!

    assert project_admin.is_project_administrator_of_any_project?
    refute not_managed_project.can_be_administered_by?(project_admin)

    subject = Factory(:person)
    assert subject.can_be_administered_by?(project_admin)

    bad_wg = not_managed_project.work_groups.first
    login_as project_admin
    put :administer_update, id: subject.id, person: { work_group_ids: [bad_wg.id] }
    assert_response :redirect
    refute_nil flash[:error]
    subject.reload
    refute_includes subject.projects, not_managed_project
  end

  test 'allow project administrator to assign people into only their projects' do
    project_admin = Factory(:project_administrator)

    project_administrator_work_group_ids = project_admin.projects.map(&:work_groups).flatten.map(&:id)
    a_person = Factory(:person)

    login_as(project_admin)
    put :administer_update, id: a_person.id, person: { work_group_ids: project_administrator_work_group_ids }

    assert_redirected_to person_path(assigns(:person))
    assert_equal project_admin.projects.sort(&:title), assigns(:person).work_groups.map(&:project).sort(&:title)
  end

  test 'not allow project administrator to assign people into projects that they are not in' do
    project_admin = Factory(:project_administrator)
    a_person = Factory(:person)
    a_work_group = Factory(:work_group)
    assert_not_nil a_work_group.project

    login_as(project_admin.user)
    put :administer_update, id: a_person.id, person: { work_group_ids: [a_work_group.id] }

    assert_redirected_to :root
    assert_not_nil flash[:error]
    a_person.reload
    assert !a_person.work_groups.include?(a_work_group)
  end

  test 'project administrator see only their projects to assign people into' do
    project_admin = Factory(:project_administrator)
    a_person = Factory(:person, group_memberships: [Factory(:group_membership, work_group: project_admin.group_memberships.first.work_group)])

    workgroup = Factory(:work_group)

    login_as(project_admin)
    get :admin, id: a_person

    assert_response :success

    project_admin.projects.each do |project|
      assert_select 'optgroup[label=?]', project.title, count: 1 do
        project.institutions.each do |institution|
          assert_select 'option', text: institution.title, count: 1
        end
      end
    end

    assert_select 'optgroup[label=?]', workgroup.project.title, count: 0
    assert_select 'option', text: workgroup.institution.title, count: 0
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
    get :edit, id: person

    assert_response :success

    put :update, id: person, person: { first_name: 'blabla' }

    assert_redirected_to person_path(assigns(:person))
    person = assigns(:person)
    assert_equal 'blabla', person.first_name
  end

  test "project administrator can view profile creation" do
    login_as(Factory(:project_administrator))
    get :new
    assert_response :success
  end

  test "project administrator can create new profile" do
    login_as(Factory(:project_administrator))
    assert_difference('Person.count') do
      post :create, person: { first_name: 'test', email: 'ttt@email.com' }
    end
    person = assigns(:person)
    refute_nil person
    assert_equal "test",person.first_name
    assert_equal "ttt@email.com",person.email
  end

  test "normal user cannot can view profile creation" do
    login_as(Factory(:person))
    get :new
    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test "normal user cannot create new profile" do
    login_as(Factory(:person))
    assert_no_difference('Person.count') do
      post :create, person: { first_name: 'test', email: 'ttt@email.com' }
    end
    assert_redirected_to :root
    refute_nil flash[:error]
  end

  test 'cannot update person roles mask' do
    login_as(Factory(:admin))
    person = Factory(:person)
    put :update, id: person, person: { first_name: 'blabla', roles_mask: mask_for_admin }
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
    get :edit, id: a_person

    assert_response :redirect
    assert_not_nil flash[:error]

    put :update, id: a_person, person: { first_name: 'blabla' }

    assert_response :redirect
    assert_not_nil flash[:error]
    a_person.reload
    assert_not_equal 'blabla', a_person.first_name
  end

  test 'project administrator can not edit admin' do
    project_admin = Factory(:project_administrator)
    admin = Factory(:admin, group_memberships: [Factory(:group_membership, work_group: project_admin.group_memberships.first.work_group)])

    login_as(project_admin)
    get :show, id: admin
    assert_select 'a', text: /Edit Profile/, count: 0

    get :edit, id: admin

    assert_response :redirect
    assert_not_nil flash[:error]

    put :update, id: admin, person: { first_name: 'blablba' }

    assert_response :redirect
    assert_not_nil flash[:error]

    refute_equal 'blablba', assigns(:person).first_name
  end

  # test 'admin can administer other admin' do
  #   admin = Factory(:admin)
  #   project = admin.projects.first
  #
  #   get :show, id: admin
  #   assert_select 'a', text: /Person Administration/, count: 1
  #
  #   get :admin, id: admin
  #   assert_response :success
  #
  #   assert !admin.is_asset_gatekeeper?(project)
  #   put :administer_update, id: admin, person: {}, roles: { asset_gatekeeper: [project.id] }
  #   assert_redirected_to person_path(admin)
  #   assert assigns(:person).is_asset_gatekeeper?(project)
  #   assert assigns(:person).is_admin?
  # end

  test "project admin can set roles for people in projects he admins" do
    project_admin = Factory(:project_administrator)
    login_as(project_admin)
    person = Factory(:person)
    project = project_admin.projects.first
    person.add_to_project_and_institution(project,project_admin.institutions.first)
    person.save!
    refute person.is_project_administrator?(project)
    refute person.is_asset_gatekeeper?(project)

    put :administer_update, id: person, person: {}, roles: { asset_gatekeeper: [project.id], project_administrator:[project.id] }
    assert_redirected_to person_path(person)
    assert assigns(:person).is_asset_gatekeeper?(project)
    assert assigns(:person).is_project_administrator?(project)
  end

  test "project admin cannot set roles for people in projects he doesn't admin" do
    project_admin = Factory(:project_administrator)
    login_as(project_admin)
    person = Factory(:person)
    project = person.projects.first

    refute_nil project
    refute project_admin.is_project_administrator?(project)
    refute person.is_project_administrator?(project)
    refute person.is_asset_gatekeeper?(project)

    put :administer_update, id: person, person: {}, roles: { asset_gatekeeper: [project.id], project_administrator:[project.id] }
    assert_redirected_to person_path(person)

    refute assigns(:person).is_asset_gatekeeper?(project)
    refute assigns(:person).is_project_administrator?(project)
  end

  test "roles are preserved for a project the project admin doesn't admin but was already set" do
    project_admin = Factory(:project_administrator)
    login_as(project_admin)
    person = Factory(:person)
    project = person.projects.first
    managed_project = project_admin.projects.first
    person.add_to_project_and_institution managed_project,person.institutions.first

    #make project admin for other project
    person.is_project_administrator=true,project
    person.is_admin=true
    disable_authorization_checks{person.save!}

    assert project_admin.is_project_administrator?(managed_project)
    assert person.is_project_administrator?(project)
    refute person.is_project_administrator?(managed_project)

    put :administer_update, id: person, person: {}, roles: { project_administrator:[managed_project.id] }
    assert_redirected_to person_path(person)

    assert assigns(:person).is_admin?
    assert assigns(:person).is_project_administrator?(project)
    assert assigns(:person).is_project_administrator?(managed_project)
  end

  test "non project roles are not removed" do

    person = Factory(:programme_administrator)
    prog = person.programmes.first
    proj = person.projects.first
    person.is_admin=true
    person.save!
    person.reload

    assert person.is_admin?
    assert person.is_programme_administrator?(prog)
    refute person.is_project_administrator?(proj)

    put :administer_update, id: person, person: {}, roles: { project_administrator:[proj.id] }
    assert_redirected_to person_path(person)

    assert assigns(:person).is_admin?
    assert assigns(:person).is_project_administrator?(proj)
    assert assigns(:person).is_programme_administrator?(prog)
  end

  test "project admin cannot make somebody an system admin even in the same project" do
    project_admin = Factory(:project_administrator)
    login_as(project_admin)
    person = Factory(:person)
    project = project_admin.projects.first
    person.add_to_project_and_institution(project,project_admin.institutions.first)
    person.save!
    refute person.is_admin?

    put :administer_update, id: person, person: {}, roles: { admin: [] }
    assert_redirected_to person_path(person)
    refute assigns(:person).is_admin?
  end

  test 'admin can edit other admin' do
    admin = Factory(:admin)
    assert_not_nil admin.user
    assert_not_equal User.current_user, admin.user

    get :show, id: admin
    assert_select 'a', text: /Edit Profile/, count: 1

    get :edit, id: admin
    assert_response :success

    assert_not_equal 'test', admin.title
    put :update, id: admin, person: { first_name: 'test' }
    assert_redirected_to person_path(admin)
    assert_equal 'test', assigns(:person).first_name
  end

  test 'can edit themself' do
    login_as(:fred)
    get :show, id: people(:fred)
    assert_select 'a', text: /Edit Profile/, count: 1

    get :edit, id: people(:fred)
    assert_response :success

    put :update, id: people(:fred), person: { first_name: 'fred1' }
    assert_redirected_to assigns(:person)
    assert_equal 'fred1', assigns(:person).first_name
  end

  test 'can not administer themself' do
    login_as(:fred)
    get :show, id: people(:fred)
    assert_select 'a', text: /Person Administration/, count: 0

    get :admin, id: people(:fred)
    assert_redirected_to :root
    assert_not_nil flash[:error]

    get :administer_update, id: people(:fred), person: {}
    assert_redirected_to :root
    assert_not_nil flash[:error]
  end


  test 'if not admin login should not show the registered date for this person' do
    login_as(:aaron)
    a_person = Factory(:person)
    get :show, id: a_person
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

  test 'set gatekeeper role for a person along with workgroup' do
    work_group = Factory(:work_group)
    assert_difference('Person.count') do
      assert_difference('NotifieeInfo.count') do
        post :create, person: { first_name: 'test', email: 'hghg@sdfsd.com' }
      end
    end
    person = assigns(:person)
    put :administer_update, id: person, person: { work_group_ids: [work_group.id] }, roles: { asset_gatekeeper: [work_group.project.id] }

    person = assigns(:person)
    assert_not_nil person
    assert person.is_asset_gatekeeper?(work_group.project)
  end

  test 'should have gatekeeper icon on person show page' do
    gatekeeper = Factory(:asset_gatekeeper)
    get :show, id: gatekeeper
    assert_select 'img[src*=?]', /medal_silver_2.png/, count: 1
  end

  test 'should have gatekeeper icon on people index page' do
    (0..5).each do
      Factory(:asset_gatekeeper)
    end
    get :index
    gatekeeper_number = assigns(:people).select(&:is_asset_gatekeeper_of_any_project?).count
    assert_select 'img[src*=?]', /medal_silver_2/, count: gatekeeper_number
  end

  test 'unsubscribe to a project should unsubscribe all the items of that project' do
    with_config_value 'email_enabled', true do
      proj = Factory(:project)
      sop = Factory(:sop, project_ids: [proj.id], policy: Factory(:public_policy))
      df = Factory(:data_file, project_ids: [proj.id], policy: Factory(:public_policy))

      # subscribe to project
      current_person = User.current_user.person
      put :update, id: current_person, receive_notifications: true, person: { project_subscriptions_attributes: { '0' => { project_id: proj.id, frequency: 'weekly', _destroy: '0' } } }
      assert_redirected_to current_person

      project_subscription_id = ProjectSubscription.find_by_project_id(proj.id).id
      assert_difference 'Subscription.count', 2 do
        ProjectSubscriptionJob.new(project_subscription_id).perform
      end
      assert sop.subscribed?(current_person)
      assert df.subscribed?(current_person)
      assert current_person.receive_notifications?

      assert_emails 1 do
        Factory(:activity_log, activity_loggable: sop, action: 'update')
        Factory(:activity_log, activity_loggable: df, action: 'update')
        SendPeriodicEmailsJob.new('weekly').perform
      end

      # unsubscribe to project
      put :update, id: current_person, receive_notifications: true, person: { project_subscriptions_attributes: { '0' => { id: current_person.project_subscriptions.first.id, project_id: proj.id, frequency: 'weekly', _destroy: '1' } } }
      assert_redirected_to current_person
      assert current_person.project_subscriptions.empty?

      sop.reload
      df.reload
      assert !sop.subscribed?(current_person)
      assert !df.subscribed?(current_person)
      assert current_person.receive_notifications?

      assert_emails 0 do
        Factory(:activity_log, activity_loggable: sop, action: 'update')
        Factory(:activity_log, activity_loggable: df, action: 'update')
        SendPeriodicEmailsJob.new('weekly').perform
      end
    end
  end

  test 'should subscribe a person to a project when assign a person to that project' do
    a_person = Factory(:brand_new_person)
    project = Factory(:project)
    work_group = Factory(:work_group, project: project)
    refute a_person.work_groups.include?(work_group)
    refute a_person.project_subscriptions.map(&:project).include?(project)

    assert_difference('ProjectSubscription.count', 1) do
      put :administer_update, id: a_person, person: { work_group_ids: [work_group.id] }
    end

    assert_redirected_to a_person
    a_person.reload
    assert a_person.work_groups.include?(work_group)
    assert a_person.project_subscriptions.map(&:project).include?(project)
  end

  test 'should unsubscribe a person to a project when unassign a person to that project' do
    project = Factory :project
	  person = Factory(:brand_new_person,:work_groups => [Factory(:work_group, :project => project)])
    assert_equal  project, person.projects.first
    assert person.project_subscriptions.map(&:project).include?(project)

    s = Factory(:subscribable, project_ids: [project.id])
    SetSubscriptionsForItemJob.new(s, [project]).perform
    s.reload
    assert s.subscribed?(person)

    # unassign a person to a project
    assert_difference('ProjectSubscription.count', -1) do
      put :administer_update, id: person, person: { work_group_ids: [] }
    end

    assert_redirected_to person
    person.reload
    assert_empty person.work_groups
    assert_empty person.projects
    refute person.project_subscriptions.map(&:project).include?(projects.first)
    s.reload
    refute s.subscribed?(person)
  end

  test 'should show subscription list to only yourself and admin' do
    a_person = Factory(:person)
    login_as(a_person.user)
    get :show, id: a_person
    assert_response :success
    assert_select 'div.panel-heading', text: 'Subscriptions', count: 1

    logout

    login_as(:quentin)
    get :show, id: a_person
    assert_response :success
    assert_select 'div.panel-heading', text: 'Subscriptions', count: 1
  end

  test 'should not show subscription list to people that are not yourself and admin' do
    a_person = Factory(:person)
    login_as(Factory(:user))
    get :show, id: a_person
    assert_response :success
    assert_select 'div.panel-heading', text: 'Subscriptions', count: 0

    logout

    get :show, id: a_person
    assert_response :success
    assert_select 'div.panel-heading', text: 'Subscriptions', count: 0
  end

  test 'virtual liver blocks access to profile page whilst logged out' do
    a_person = Factory(:person)
    logout
    as_virtualliver do
      get :show, id: a_person
      assert_response :forbidden
    end
  end

  test 'should update page limit_latest when changing the setting from admin' do
    assert_equal 'latest', Seek::Config.default_pages[:people]
    assert_not_equal 5, Seek::Config.limit_latest

    Seek::Config.limit_latest = 5
    get :index
    assert_response :success
    assert_select ".pagination li.active" do
      assert_select 'a[href=?]', people_path(page: 'latest')
    end
    assert_select 'div.list_item_title', count: 5
  end

  test 'people not in projects should not be shown in index'  do
    person_not_in_project = Factory(:brand_new_person, first_name: 'Person Not In Project')
    person_in_project = Factory(:person, first_name: 'Person in Project')
    assert person_not_in_project.projects.empty?
    assert !person_in_project.projects.empty?
    get :index
    assert_response :success
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item_title  a[href=?]', person_path(person_in_project), text: /#{person_in_project.name}/, count: 1
      assert_select 'div.list_item_title  a[href=?]', person_path(person_not_in_project), text: /#{person_not_in_project.name}/, count: 0
    end

    get :index, page: 'P'
    assert_response :success
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item_title  a[href=?]', person_path(person_in_project), text: /#{person_in_project.name}/, count: 1
      assert_select 'div.list_item_title  a[href=?]', person_path(person_not_in_project), text: /#{person_not_in_project.name}/, count: 0
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
    get :index, project_id: proj.id
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
    get :index, presentation_id: presentation1.id

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

    get :index, programme_id: prog1.id
    assert_response :success

    assert_select 'div.list_item_title' do
      assert_select 'a[href=?]', person_path(person1), text: person1.name
      assert_select 'a[href=?]', person_path(person2), text: person2.name, count: 0
    end
  end

  test 'should show personal tags according to config' do
    p = Factory(:person)
    get :show, id: p.id
    assert_response :success
    assert_select 'div#personal_tags', count: 1
    with_config_value :tagging_enabled, false do
      get :show, id: p.id
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

    get :show, id: person.id
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

  test "should not email user after assigned to a project if they are not registered" do
    new_person = Factory(:brand_new_person)
    admin = Factory(:admin)
    work_group = Factory(:work_group)

    refute new_person.user
    login_as admin.user

    assert_no_emails do
      put :administer_update, :id => new_person.id, :person => {:work_group_ids => [work_group.id]}
    end

    assert_redirected_to person_path(new_person)

    assert_includes assigns(:person).work_groups, work_group
  end

  test "should email user after assigned to a project if they are registered" do
    new_person = Factory(:brand_new_person,:user=>Factory(:user))
    admin = Factory(:admin)
    work_group = Factory(:work_group)

    assert new_person.user
    login_as admin.user

    assert_emails(1) do
      put :administer_update, :id => new_person.id, :person => {:work_group_ids => [work_group.id]}
    end

    assert_redirected_to person_path(new_person)

    assert_includes assigns(:person).work_groups, work_group
  end

  test "should not email user after assigned to a project, if they were already in one" do
    established_person = Factory(:person)
    admin = Factory(:admin)
    work_group = Factory(:work_group)

    login_as admin.user

    assert_emails 0 do
      put :administer_update, id: established_person.id, person: { work_group_ids: [work_group.id] }
    end

    assert_redirected_to person_path(established_person)

    assert_includes assigns(:person).work_groups, work_group
  end

  test "should email admin and project administrators when specifying project" do
    proj_man1=Factory :project_administrator
    proj_man2=Factory :project_administrator
    proj1=proj_man1.projects.first
    proj2=proj_man2.projects.first
    project_without_manager = Factory :project

    #check there are 3 uniq projects
    assert_equal 3,[proj1,proj2,project_without_manager].uniq.size

    user = Factory :activated_user
    assert_nil user.person
    login_as(user)

    #3 emails - 1 to admin and 2 to project administrators
    assert_emails(3) do
      post :create,
           :person=>{:first_name=>"Fred",:last_name=>"BBB",:email=>"fred.bbb@email.com"},
           :projects=>[proj1.id,proj2.id,project_without_manager.id]
    end

    assert assigns(:person)
    user.reload
    assert_equal user.person,assigns(:person)
  end
  test 'redirect after destroy' do
    person1 = Factory(:person)
    person2 = Factory(:person)

    @request.env['HTTP_REFERER'] = "/people/#{person1.id}"
    assert_difference('Person.count', -1) do
      delete :destroy, id: person1
    end
    assert_redirected_to people_path

    @request.env['HTTP_REFERER'] = '/admin'
    assert_difference('Person.count', -1) do
      delete :destroy, id: person2
    end
    assert_redirected_to admin_path
  end

  test "contact details only visible for programme" do
    person1 = Factory(:person, :email=>"fish@email.com",:skype_name=>"fish")
    person2 = Factory(:person,:email=>"monkey@email.com",:skype_name=>"monkey")
    person3 = Factory(:person,:email=>"parrot@email.com",:skype_name=>"parrot")

    prog1 = Factory :programme,:projects=>(person1.projects | person2.projects)
    prog2 = Factory :programme,:projects=>person3.projects

    #check programme assignment
    assert_equal person1.programmes,person2.programmes
    refute_equal person1.programmes,person3.programmes

    login_as(person1)

    #should see for person2
    get :show,id: person2
    assert_select "div#contact_details",:count=>1
    assert_select "div#email",:text=>/monkey@email.com/,:count=>1
    assert_select "div#skype",:text=>/monkey/,:count=>1

    #should not see for person3 in different programme
    get :show,id: person3
    assert_select "div#contact_details",:count=>0
    assert_select "div#email",:text=>/parrot@email.com/,:count=>0
    assert_select "div#skype",:text=>/parrot/,:count=>0

  end

  test "is this you? page for register with matching email" do
    u = Factory(:brand_new_user)
    refute u.person
    p = Factory(:brand_new_person,:email=>"jkjkjk@theemail.com")
    login_as(u)
    get :register,:email=>"jkjkjk@theemail.com"
    assert_response :success
    assert_select "h1",:text=>"Is this you?",:count=>1
    assert_select "p.list_item_attribute",:text=>/#{p.name}/,:count=>1
    assert_select "h1",:text=>"New profile",:count=>0
  end

  test "new profile page when matching email matches person already registered" do
    u = Factory(:brand_new_user)
    refute u.person
    p = Factory(:person,:email=>"jkjkjk@theemail.com")
    login_as(u)
    get :register,:email=>"jkjkjk@theemail.com"
    assert_response :success
    assert_select "h1",:text=>"Is this you?",:count=>0
    assert_select "h1",:text=>"New profile",:count=>1
  end


  test "orcid not required when creating another person's profile" do
    login_as(Factory(:admin))

    with_config_value(:orcid_required, true) do
      assert_nothing_raised do
        no_orcid = Factory :brand_new_person, :email => "FISH-sOup1@email.com"
        assert no_orcid.valid?
        assert_empty no_orcid.errors[:orcid]
      end
    end
  end

  def mask_for_admin
    Seek::Roles::Roles.instance.mask_for_role("admin")
  end

  def mask_for_pal
    Seek::Roles::Roles.instance.mask_for_role("pal")
  end
end
