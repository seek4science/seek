require 'test_helper'

class PeopleControllerTest < ActionController::TestCase

  fixtures :people,:users, :projects, :work_groups, :group_memberships, :project_roles

  include AuthenticatedTestHelper
  include RestTestCases
  include ApplicationHelper
  include RdfTestCases

  def setup
    login_as(:quentin)
  end

  def rest_api_test_object
    @object=people(:quentin_person)
  end

  def test_title
    get :index
    assert_select "title", :text=>/The Sysmo SEEK People.*/, :count=>1
  end

  def test_xml_for_person_with_tools_and_expertise
    p=Factory :person
    Factory :expertise,:value=>"golf",:annotatable=>p
    Factory :expertise,:value=>"fishing",:annotatable=>p
    Factory :tool,:value=>"fishing rod",:annotatable=>p

    test_get_rest_api_xml p

    doc = LibXML::XML::Document.string(@response.body)
    doc.root.namespaces.default_prefix="s"
    assert_equal 2, doc.find("//s:tags/s:tag[@context='expertise']").count
    assert_equal 1,doc.find("//s:tags/s:tag[@context='tool']").count
    assert_equal "fishing rod",doc.find("//s:tags/s:tag[@context='tool']").first.content
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

  def test_first_registered_person_is_admin

    Person.destroy_all
    assert_equal 0, Person.count, "There should be no people in the database"
    user = Factory(:activated_user)
    login_as user

    assert_difference('Person.count') do
      assert_difference('NotifieeInfo.count') do
        post :create, :person => {:first_name=>"test", :email=>"hghg@sdfsd.com"}
      end
    end
    assert assigns(:person)
    person = Person.find(assigns(:person).id)
    assert person.is_admin?
    assert person.only_first_admin_person?
    assert_redirected_to registration_form_path(:during_setup=>"true")
  end


  def test_second_registered_person_is_not_admin
      Person.delete_all
      person = Person.new(:first_name=>"fred", :email=>"fred@dddd.com")
      person.save!
      assert_equal 1, Person.count, "There should be 1 person in the database"
      user = Factory(:activated_user)
      login_as user
      assert_difference('Person.count') do
        assert_difference('NotifieeInfo.count') do
          post :create, :person => {:first_name=>"test", :email=>"hghg@sdfsd.com"}
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
        post :create, :person => {:first_name=>"test", :email=>"hghg@sdfsd.com"}
      end
    end

    assert_redirected_to person_path(assigns(:person))
    assert_equal "T", assigns(:person).first_letter
    assert_not_nil Person.find(assigns(:person).id).notifiee_info
  end

  def test_should_create_person_with_project
    work_group_id = Factory(:work_group).id
    assert_difference('Person.count') do
      assert_difference('NotifieeInfo.count') do
        post :create, :person => {:first_name=>"test", :email=>"hghg@sdfsd.com"}
      end
    end

    assert_redirected_to person_path(assigns(:person))
    assert_equal "T", assigns(:person).first_letter

    put :administer_update, :id => assigns(:person), :person => {:work_group_ids => [work_group_id]}

    assert_redirected_to person_path(assigns(:person))
    assert_equal [work_group_id], assigns(:person).work_group_ids
    assert_not_nil Person.find(assigns(:person).id).notifiee_info
  end

  def test_created_person_should_receive_notifications
    post :create, :person => {:first_name=>"test", :email=>"hghg@sdfsd.com"}
    p=assigns(:person)
    assert_not_nil p.notifiee_info
    assert p.notifiee_info.receive_notifications?
  end

  test "non_admin_should_not_create_pal" do
    login_as(:pal_user)
    assert_difference('Person.count') do
      post :create, :person => {:first_name=>"test", :email=>"hghg@sdfsd.com"}
    end

    p=assigns(:person)
    assert_redirected_to person_path(p)

    put :administer_update, :id => assigns(:person), :person => {:roles_mask => Person::ROLES_MASK_FOR_PAL}

    p=assigns(:person)
    assert_redirected_to :root
    assert !p.is_pal?
    assert !Person.find(p.id).is_pal?
  end

  def test_should_show_person
    get :show, :id => people(:quentin_person)
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => people(:quentin_person)
    assert_response :success
  end

  def test_non_admin_cant_edit_someone_else
    login_as(:fred)
    get :edit, :id=> people(:aaron_person)
    assert_redirected_to people(:aaron_person)
  end

  def test_project_manager_can_edit_others_inside_their_projects
    login_as(:project_manager)
    assert !(users(:project_manager).person.projects & people(:aaron_person).projects).empty?
    get :edit, :id=> people(:aaron_person)
    assert_response :success
  end

  def test_admin_can_edit_others
    get :edit, :id=>people(:aaron_person)
    assert_response :success
  end

  def test_change_notification_settings
    login_as(:quentin)
    p=people(:fred)
    assert p.notifiee_info.receive_notifications?, "should receive noticiations by default in fixtures"

    put :update, :id=>p.id, :person=>{:id=>p.id}
    assert !Person.find(p.id).notifiee_info.receive_notifications?

    put :update, :id=>p.id, :person=>{:id=>p.id}, :receive_notifications=>true
    assert Person.find(p.id).notifiee_info.receive_notifications?

  end

  def test_admin_can_set_is_admin_flag
    login_as(:quentin)
    p=people(:fred)
    assert !p.is_admin?
    put :administer_update, :id=>p.id, :person=>{:id=>p.id, :roles_mask=>Person::ROLES_MASK_FOR_ADMIN}
    assert_redirected_to person_path(p)
    assert_nil flash[:error]
    p.reload
    assert p.is_admin?
  end

  def test_non_admin_cant_set__is_admin_flag
    login_as(:aaron)
    p=people(:fred)
    assert !p.is_admin?
    put :administer_update, :id=>p.id, :person=>{:id=>p.id, :roles_mask=>Person::ROLES_MASK_FOR_ADMIN}
    assert_not_nil flash[:error]
    p.reload
    assert !p.is_admin?
  end

  def test_admin_can_set_pal_flag
    login_as(:quentin)
    p=people(:fred)
    assert !p.is_pal?
    put :administer_update, :id=>p.id, :person=>{:id=>p.id, :email=>"ssfdsd@sdfsdf.com"}, :roles => {:pal => true}
    assert_redirected_to person_path(p)
    assert_nil flash[:error]
    p.reload
    assert p.is_pal?
  end

  def test_non_admin_cant_set_pal_flag
    login_as(:aaron)
    p=people(:fred)
    assert !p.is_pal?
    put :administer_update, :id=>p.id, :person=>{:id=>p.id, :email=>"ssfdsd@sdfsdf.com"}, :roles => {:pal => true}
    assert_not_nil flash[:error]
    p.reload
    assert !p.is_pal?
  end

  def test_cant_set_yourself_to_pal
    login_as(:aaron)
    p=people(:aaron_person)
    assert !p.is_pal?
    put :administer_update, :id=>p.id, :person=>{:id=>p.id, :email=>"ssfdsd@sdfsdf.com"}, :roles => {:pal => true}
    p.reload
    assert !p.is_pal?
  end

  def test_cant_set_yourself_to_admin
    login_as(:aaron)
    p=people(:aaron_person)
    assert !p.is_admin?
    put :administer_update, :id=>p.id, :person=>{:id=>p.id, :roles_mask=>Person::ROLES_MASK_FOR_ADMIN, :email=>"ssfdsd@sdfsdf.com"}
    p.reload
    assert !p.is_admin?
  end

  def test_non_admin_cant_set_can_edit_institutions
    login_as(:aaron)
    p=people(:aaron_person)
    assert !p.can_edit_institutions?
    put :administer_update, :id=>p.id, :person=>{:id=>p.id, :can_edit_institutions=>true, :email=>"ssfdsd@sdfsdf.com"}
    p.reload
    assert !p.can_edit_institutions?
  end

  def test_non_admin_cant_set_can_edit_projects
    login_as(:aaron)
    p=people(:aaron_person)
    assert !p.can_edit_projects?
    put :administer_update, :id=>p.id, :person=>{:id=>p.id, :can_edit_projects=>true, :email=>"ssfdsd@sdfsdf.com"}
    p.reload
    assert !p.can_edit_projects?
  end

  def test_can_edit_person_and_user_id_different
    #where a user_id for a person are not the same
    login_as(:fred)
    get :edit, :id=>people(:fred)
    assert_response :success
  end

  def test_not_current_user_doesnt_show_link_to_change_password
    get :edit, :id => people(:aaron_person)
    assert_select "a", :text=>"Change password", :count=>0
  end

  def test_current_user_shows_seek_id
    login_as(:quentin)
    get :show, :id=> people(:quentin_person)
    assert_select ".box_about_actor p", :text=>/Seek ID: /m
    assert_select ".box_about_actor p", :text=>/Seek ID: .*#{people(:quentin_person).id}/m, :count=>1
  end

  def test_not_current_user_doesnt_show_seek_id
    get :show, :id=> people(:aaron_person)
    assert_select ".box_about_actor p", :text=>/Seek ID :/, :count=>0
  end

  def test_current_user_shows_login_name
    current_user = Factory(:person).user
    login_as(current_user)
    get :show, :id=> current_user.person
    assert_select ".box_about_actor p", :text=>/Login/m
    assert_select ".box_about_actor p", :text=>/Login.*#{current_user.login}/m
  end

  def test_not_current_user_doesnt_show_login_name
    current_user = Factory(:person).user
    other_person = Factory(:person)
    login_as(current_user)
    get :show, :id=> other_person
    assert_select ".box_about_actor p", :text=>/Login/m, :count=>0
  end

  def test_admin_sees_non_current_user_login_name
    current_user = Factory(:admins).user
    other_person = Factory(:person)
    login_as(current_user)
    get :show, :id=> other_person
    assert_select ".box_about_actor p", :text=>/Login/m
    assert_select ".box_about_actor p", :text=>/Login.*#{other_person.user.login}/m
  end

  def test_should_update_person
    put :update, :id => people(:quentin_person), :person => {}
    assert_redirected_to person_path(assigns(:person))
  end

  def test_should_not_update_somebody_else_if_not_admin
    login_as(:aaron)
    quentin=people(:quentin_person)
    put :update, :id => people(:quentin_person), :person => {:email=>"kkkkk@kkkkk.com"}
    assert_not_nil flash[:error]
    quentin.reload
    assert_equal "quentin@email.com", quentin.email
  end

  def test_should_destroy_person
    assert_difference('Person.count', -1) do
      delete :destroy, :id => people(:quentin_person)
    end

    assert_redirected_to people_path
  end

  def test_should_add_nofollow_to_links_in_show_page
    get :show, :id=> people(:person_with_links_in_description)
    assert_select "div#description" do
      assert_select "a[rel=nofollow]"
    end
  end

  test "filtering by project" do
    project=projects(:sysmo_project)
    get :index, :filter => {:project => project.id}
    assert_response :success
  end

  test "finding by role" do
    role=project_roles(:member)
    get :index, :project_role_id=>role.id
    assert_response :success
    assert assigns(:people)
    assert assigns(:people).include?(people(:person_for_model_owner))
  end

  test "admin can manage person" do
    login_as(:quentin)
    person = people(:aaron_person)
    assert person.can_manage?
  end

  test "non-admin users + anonymous users can not manage person " do
    login_as(:aaron)
    person = people(:quentin_person)
    assert !person.can_manage?

    logout
    assert !person.can_manage?
  end

  test 'should remove every permissions set on the person before deleting him' do
    login_as(:quentin)
    person = Factory(:person)
    #create bunch of permissions on this person
    i = 0
    while i < 10
      Factory(:permission, :contributor => person, :access_type => rand(5))
      i += 1
    end
    permissions = Permission.find(:all, :conditions => ["contributor_type =? and contributor_id=?", 'Person', person.try(:id)])
    assert_equal 10, permissions.count

    assert_difference('Person.count', -1) do
      delete :destroy, :id => person
    end

    permissions = Permission.find(:all, :conditions => ["contributor_type =? and contributor_id=?", 'Person', person.try(:id)])
    assert_equal 0, permissions.count
  end

  test 'should set the manage right on pi before deleting the person' do
    login_as(:quentin)

    project = Factory(:project)
    work_group = Factory(:work_group, :project => project)
    person = Factory(:person_in_project, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
    user = Factory(:user, :person => person)
    #create a datafile that this person is the contributor
    data_file = Factory(:data_file, :contributor => user, :project_ids => [project.id])
    #create pi
    role = ProjectRole.find_by_name('PI')
    pi = Factory(:person_in_project, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
    pi.group_memberships.first.project_roles << role
    pi.save
    assert_equal pi, project.pis.first

    assert_difference('Person.count', -1) do
      delete :destroy, :id => person
    end

    permissions_on_person = Permission.find(:all, :conditions => ["contributor_type =? and contributor_id=?", 'Person', person.try(:id)])
    assert_equal 0, permissions_on_person.count

    permissions = data_file.policy.permissions

    assert_equal 1, permissions.count
    assert_equal pi.id, permissions.first.contributor_id
    assert_equal Policy::MANAGING, permissions.first.access_type
  end

  test 'should set the manage right on pal (if no pi) before deleting the person' do
    login_as(:quentin)

    project = Factory(:project)
    work_group = Factory(:work_group, :project => project)
    person = Factory(:person_in_project, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
    user = Factory(:user, :person => person)
    #create a datafile that this person is the contributor and with the same project
    data_file = Factory(:data_file, :contributor => user, :project_ids => [project.id])
    #create pal
    role = ProjectRole.find_by_name('Sysmo-DB Pal')
    pal = Factory(:person_in_project, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
    pal.group_memberships.first.project_roles << role
    pal.is_pal = true
    pal.save
    assert_equal pal, project.pals.first
    assert_equal 0, project.pis.count

    assert_difference('Person.count', -1) do
      delete :destroy, :id => person
    end

    permissions_on_person = Permission.find(:all, :conditions => ["contributor_type =? and contributor_id=?", 'Person', person.try(:id)])
    assert_equal 0, permissions_on_person.count

    permissions = data_file.policy.permissions

    assert_equal 1, permissions.count
    assert_equal pal.id, permissions.first.contributor_id
    assert_equal Policy::MANAGING, permissions.first.access_type
  end

  test 'set pal role for a person' do
    work_group_id = Factory(:work_group).id
    assert_difference('Person.count') do
      assert_difference('NotifieeInfo.count') do
        post :create, :person => {:first_name=>"test", :email=>"hghg@sdfsd.com"}, :roles => {:pal => true}
      end
    end
    person = assigns(:person)
    put :administer_update, :id => person, :person =>{:work_group_ids => [work_group_id]}, :roles => {:pal => true}

    person = assigns(:person)
    assert_not_nil person
    assert person.is_pal?
  end

  test 'set project_manager role for a person' do
    work_group_id = Factory(:work_group).id
    assert_difference('Person.count') do
      assert_difference('NotifieeInfo.count') do
        post :create, :person => {:first_name=>"test", :email=>"hghg@sdfsd.com"}
      end
    end

    person = assigns(:person)
    put :administer_update, :id => person, :person =>{:work_group_ids => [work_group_id]}, :roles => {:project_manager => true}
    person = assigns(:person)
    assert_not_nil person
    assert person.is_project_manager?
  end

  test 'update roles for a person' do
    person = Factory(:pal)
    assert_not_nil person
    assert person.is_pal?

    put :administer_update, :id => person.id, :person => {:id => person.id}, :roles => {:project_manager => true}

    person = assigns(:person)
    person.reload
    assert_not_nil person
    assert person.is_project_manager?
    assert !person.is_pal?
  end

  test 'update roles for yourself, but keep the admin role' do
    person = User.current_user.person
    assert person.is_admin?
    assert_equal 1, person.roles.count

    put :administer_update, :id => person.id, :person => {:id => person.id}, :roles => {:project_manager => true}

    person = assigns(:person)
    person.reload
    assert_not_nil person
    assert person.is_project_manager?
    assert person.is_admin?
    assert_equal 2, person.roles.count
  end

  test 'set the asset manager role for a person' do
    work_group_id = Factory(:work_group).id
    assert_difference('Person.count') do
      assert_difference('NotifieeInfo.count') do
        post :create, :person => {:first_name=>"assert manager", :email=>"asset_manager@sdfsd.com"}
      end
    end
    person = assigns(:person)
    put :administer_update, :id => person, :person =>{:work_group_ids => [work_group_id]}, :roles => {:asset_manager => true}
    person = assigns(:person)

    assert_not_nil person
    assert person.is_asset_manager?
  end

  test 'admin should see the session of assigning roles to a person' do
    person = Factory(:person)
    get :admins, :id => person
    assert_select "input#_roles_asset_manager", :count => 1
    assert_select "input#_roles_project_manager", :count => 1
    assert_select "input#_roles_gatekeeper", :count => 1
  end

  test 'non-admin should not see the session of assigning roles to a person' do
    login_as(:aaron)
    person = Factory(:person)
    get :admins, :id => person
    assert_select "input#_roles_asset_manager", :count => 0
    assert_select "input#_roles_project_manager", :count => 0
    assert_select "input#_roles_gatekeeper", :count => 0
  end

  test 'should show that the person is asset manager for admin' do
    person = Factory(:person)
    person.is_asset_manager = true
    person.save!
    get :show, :id => person
    assert_select "li", :text => /This person is an asset manager/, :count => 1
  end

  test 'should not show that the person is asset manager for non-admin' do
    person = Factory(:person)
    person.is_asset_manager = true
    person.save
    login_as(:aaron)
    get :show, :id => person
    assert_select "li", :text => /This person is an asset manager/, :count => 0
  end

  def test_project_manager_can_administer_others
    login_as(:project_manager)
    get :admins, :id=> people(:aaron_person)
    assert_response :success
  end

  def test_admin_can_administer_others
    login_as(:quentin)
    get :admins, :id=>people(:aaron_person)
    assert_response :success

  end

  test 'non-admin can not administer others' do
    login_as(:fred)
    get :admins, :id=> people(:aaron_person)
    assert_redirected_to :root
  end

  test 'can not administer yourself' do
    aaron = people(:aaron_person)
    login_as(aaron.user)
    get :admins, :id=> aaron
    assert_redirected_to :root
  end

  test 'should have asset manager icon on person show page' do
    asset_manager = Factory(:asset_manager)
    get :show, :id => asset_manager
    assert_select "img[src*=?]", /medal_bronze_3.png/,:count => 1
  end

  test 'should have asset manager icon on people index page' do
    i = 0
    while i < 5 do
      Factory(:asset_manager)
      i += 1
    end
    get :index
    asset_manager_number = assigns(:people).select(&:is_asset_manager?).count
    assert_select "img[src*=?]", /medal_bronze_3/, :count => asset_manager_number
  end

  test 'should have project manager icon on person show page' do
    project_manager = Factory(:project_manager)
    get :show, :id => project_manager
    assert_select "img[src*=?]", /medal_gold_1.png/, :count => 1
  end

  test 'should have project manager icon on people index page' do
    i = 0
    while i < 5 do
      Factory(:project_manager)
      i += 1
    end

    get :index

    project_manager_number = assigns(:people).select(&:is_project_manager?).count
    assert_select "img[src*=?]", /medal_gold_1.png/, :count => project_manager_number
  end

  test "allow project manager to assign people into only their projects" do
    project_manager = Factory(:project_manager)

    project_manager_work_group_ids = project_manager.projects.collect(&:work_groups).flatten.collect(&:id)
    a_person = Factory(:person)

    login_as(project_manager.user)
    put :administer_update, :id => a_person.id, :person => {:work_group_ids => project_manager_work_group_ids}

    assert_redirected_to person_path(assigns(:person))
    assert_equal project_manager.projects.sort(&:title), assigns(:person).work_groups.collect(&:project).sort(&:title)
  end

  test "not allow project manager to assign people into projects that they are not in" do
    project_manager = Factory(:project_manager)
    a_person = Factory(:person)
    a_work_group = Factory(:work_group)
    assert_not_nil a_work_group.project

    login_as(project_manager.user)
    put :administer_update, :id => a_person.id, :person => {:work_group_ids => [a_work_group.id]}

    assert_redirected_to :root
    assert_not_nil flash[:error]
    a_person.reload
    assert !a_person.work_groups.include?(a_work_group)
  end

  test "project manager see only their projects to assign people into" do
    project_manager = Factory(:project_manager)
    a_person = Factory(:person)

    login_as(project_manager.user)
    get :admins, :id => a_person

    assert_response :success

    project_manager.projects.each do |project|
      assert_select "optgroup[label=?]", project.title, :count => 1 do
        project.institutions.each do |institution|
          assert_select 'option', :text => institution.title, :count => 1
        end
      end
    end
  end

  test "project manager dont see the projects that they are not in to assign people into" do
    project_manager = Factory(:project_manager)
    a_person = Factory(:person)
    a_work_group = Factory(:work_group)
    assert_not_nil a_work_group.project

    login_as(project_manager.user)
    get :admins, :id => a_person

    assert_response :success
    assert_select "optgroup[label=?]", a_work_group.project.title, :count => 0
    assert_select 'option', :text => a_work_group.institution.title, :count => 0
  end

  test "allow project manager to edit people inside their projects, even outside their institutions" do
    project_manager = Factory(:user_not_in_project).person
    project_manager.is_project_manager = true
    project_manager.save
    assert project_manager.is_project_manager?
    assert project_manager.institutions.empty?
    assert project_manager.projects.empty?

    project = Factory(:project)
    institution1 = Factory(:institution)
    institution2 = Factory(:institution)
    project.institutions = [institution1, institution2]
    project.save
    assert_equal 2, project.institutions.count

    project_manager.work_groups = institution1.work_groups
    project_manager.save

    assert_equal 1, project_manager.institutions.count
    assert_equal institution1, project_manager.institutions.first

    assert_equal 1, project_manager.institutions.first.projects.count
    assert_equal project, project_manager.institutions.first.projects.first

    a_person = Factory(:user_not_in_project).person
    a_person.work_groups = institution2.work_groups
    a_person.save

    assert_equal 1, a_person.institutions.first.projects.count
    assert_equal project, a_person.institutions.first.projects.first

    login_as(project_manager.user)
    get :edit, :id => a_person

    assert_response :success

    put :update, :id => a_person, :person => {:first_name => 'blabla'}

    assert_redirected_to person_path(assigns(:person))
    a_person.reload
    assert_equal 'blabla', a_person.first_name
  end

  test "not allow project manager to edit people outside their projects" do
    project_manager = Factory(:project_manager)
    a_person = Factory(:person)
    assert (project_manager.projects & a_person.projects).empty?

    login_as(project_manager.user)
    get :edit, :id => a_person

    assert_redirected_to :root
    assert_not_nil flash[:error]

    put :update, :id => a_person, :person => {:first_name => 'blabla'}

    assert_redirected_to :root
    assert_not_nil flash[:error]
    a_person.reload
    assert_not_equal 'blabla', a_person.first_name
  end

  test "project manager can not administer admin" do
    project_manager = Factory(:project_manager)
    admin = Factory(:admins)

    login_as(project_manager.user)
    get :show, :id => admin
    assert_select "a", :text => /Person Administration/, :count => 0

    get :admins, :id => admin

    assert_redirected_to :root
    assert_not_nil flash[:error]

    put :administer_update, :id => admin, :person => {}

    assert_redirected_to :root
    assert_not_nil flash[:error]
  end

  test "project manager can not edit admin" do
    project_manager = Factory(:project_manager)
    admin = Factory(:admins)

    login_as(project_manager.user)
    get :show, :id => admin
    assert_select "a", :text => /Edit Profile/, :count => 0

    get :edit, :id => admin

    assert_redirected_to :root
    assert_not_nil flash[:error]

    put :update, :id => admin, :person => {}

    assert_redirected_to :root
    assert_not_nil flash[:error]
  end

  test 'admin can administer other admin' do
    admin = Factory(:admins)

    get :show, :id => admin
    assert_select "a", :text => /Person Administration/, :count => 1

    get :admins, :id => admin
    assert_response :success

    assert !admin.is_gatekeeper?
    put :administer_update, :id => admin, :person => {}, :roles => {:gatekeeper => true}
    assert_redirected_to person_path(admin)
    assert assigns(:person).is_gatekeeper?
  end

  test 'admin can edit other admin' do
    admin = Factory(:admins)
    assert_not_nil admin.user
    assert_not_equal User.current_user, admin.user

    get :show, :id => admin
    assert_select "a", :text => /Edit Profile/, :count => 1

    get :edit, :id => admin
    assert_response :success

    assert_not_equal 'test', admin.title
    put :update, :id => admin, :person => {:first_name => 'test'}
    assert_redirected_to person_path(admin)
    assert_equal 'test', assigns(:person).first_name
  end

  test "can edit themself" do
    login_as(:fred)
    get :show, :id => people(:fred)
    assert_select "a", :text => /Edit Profile/, :count => 1

    get :edit, :id=>people(:fred)
    assert_response :success

    put :update, :id=>people(:fred), :person => {:first_name => 'fred1'}
    assert_redirected_to assigns(:person)
    assert_equal 'fred1', assigns(:person).first_name
  end

  test "can not administer themself" do
    login_as(:fred)
    get :show, :id => people(:fred)
    assert_select "a", :text => /Person Administration/, :count => 0

    get :admins, :id=>people(:fred)
    assert_redirected_to :root
    assert_not_nil flash[:error]

    get :administer_update, :id=>people(:fred), :person => {}
    assert_redirected_to :root
    assert_not_nil flash[:error]
  end

  test 'project manager can set can_edit_project of person inside their projects' do
    login_as(:project_manager)
    p=people(:aaron_person)
    assert !(users(:project_manager).person.projects & p.projects).empty?
    assert !p.can_edit_projects?

    get :admins, :id => p
    assert_response :success
    assert_select "input#person_can_edit_projects", :count => 1

    put :administer_update, :id=>p.id, :person=>{:can_edit_projects=>true}
    p.reload
    assert p.can_edit_projects?
  end

  test 'project manager can not set can_edit_project of person outside their projects' do
    login_as(:project_manager)
    p=Factory(:person)
    assert (users(:project_manager).person.projects & p.projects).empty?
    assert !p.can_edit_projects?

    get :admins, :id => p
    assert_response :success
    assert_select "input#person_can_edit_projects", :count => 0

    put :administer_update, :id=>p.id, :person=>{:can_edit_projects=>true}
    p.reload
    assert !p.can_edit_projects?
  end

    test 'project manager can set can_edit_projects of person inside their projects' do
    login_as(:project_manager)
    p=people(:aaron_person)
    assert !(users(:project_manager).person.projects & p.projects).empty?
    assert !p.can_edit_institutions?

    get :admins, :id => p
    assert_response :success
    assert_select "input#person_can_edit_institutions", :count => 1

    put :administer_update, :id=>p.id, :person=>{:can_edit_institutions=>true}
    p.reload
    assert p.can_edit_institutions?
  end

  test 'project manager can not set can_edit_institutions of person outside their projects' do
    login_as(:project_manager)
    p=Factory(:person)
    assert (users(:project_manager).person.projects & p.projects).empty?
    assert !p.can_edit_institutions?

    get :admins, :id => p
    assert_response :success
    assert_select "input#person_can_edit_institutions", :count => 0

    put :administer_update, :id=>p.id, :person=>{:can_edit_institutions=>true}
    p.reload
    assert !p.can_edit_institutions?
  end

  #test "should show the registered date for this person only for admin" do
  #  a_person = Factory(:person)
  #  get :show, :id => a_person
  #  assert_response :success
  #  text = date_as_string(a_person.user.created_at)
  #  assert_select 'p', :text => /#{text}/, :count => 1
  #
  #
  #
  #  get :index
  #  assert_response :success
  #  assigns(:people).each do |person|
  #    unless person.try(:user).try(:created_at).nil?
  #      assert_select 'p', :text => /#{date_as_string(person.user.created_at)}/, :count => 1
  #    end
  #  end
  #end

  test "if not admin login should not show the registered date for this person" do
    login_as(:aaron)
    a_person = Factory(:person)
    get :show, :id => a_person
    assert_response :success
    assert_select 'p', :text => /#{date_as_string(a_person.user.created_at)}/, :count => 0

    get :index
    assert_response :success
    assigns(:people).each do |person|
      unless person.try(:user).try(:created_at).nil?
        assert_select 'p', :text => /#{date_as_string(person.user.created_at)}/, :count => 0
      end
    end
  end

  test 'set gatekeeper role for a person' do
    work_group_id = Factory(:work_group).id
    assert_difference('Person.count') do
      assert_difference('NotifieeInfo.count') do
        post :create, :person => {:first_name=>"test", :email=>"hghg@sdfsd.com"}
      end
    end
    person = assigns(:person)
    put :administer_update, :id => person, :person =>{:work_group_ids => [work_group_id]}, :roles => {:gatekeeper => true}

    person = assigns(:person)
    assert_not_nil person
    assert person.is_gatekeeper?
  end

  test 'should show that the person is gatekeeper for admin' do
    person = Factory(:person)
    person.is_gatekeeper = true
    person.save
    get :show, :id => person
    assert_select "li", :text => /This person is a gatekeeper/, :count => 1
  end

  test 'should not show that the person is gatekeeper for non-admin' do
    person = Factory(:person)
    person.is_gatekeeper = true
    person.save
    login_as(:aaron)
    get :show, :id => person
    assert_select "li", :text => /This person is a gatekeeper/, :count => 0
  end

  test 'should have gatekeeper icon on person show page' do
    gatekeeper = Factory(:gatekeeper)
    get :show, :id => gatekeeper
    assert_select "img[src*=?]", /medal_silver_2.png/,:count => 1
  end

  test 'should have gatekeeper icon on people index page' do
    i = 0
    while i < 5 do
      Factory(:gatekeeper)
      i += 1
    end
    get :index
    gatekeeper_number = assigns(:people).select(&:is_gatekeeper?).count
    assert_select "img[src*=?]", /medal_silver_2/, :count => gatekeeper_number
  end

  test 'unsubscribe to a project should unsubscribe all the items of that project' do
    temp = Seek::Config.email_enabled
    Seek::Config.email_enabled=true

    proj = Factory(:project)
    sop = Factory(:sop, :project_ids => [proj.id], :policy => Factory(:public_policy))
    df = Factory(:data_file, :project_ids => [proj.id], :policy => Factory(:public_policy))

    #subscribe to project
    current_person=User.current_user.person
    put :update, :id => current_person, :receive_notifications => true, :person => {:project_subscriptions_attributes => {'0' => {:project_id => proj.id, :frequency => 'weekly', :_destroy => '0'}}}
    assert_redirected_to current_person

    project_subscription_id = ProjectSubscription.find_by_project_id(proj.id).id
    assert_difference "Subscription.count",2 do
      ProjectSubscriptionJob.new(project_subscription_id).perform
    end
    assert sop.subscribed?(current_person)
    assert df.subscribed?(current_person)
    assert current_person.receive_notifications?

    assert_emails 1 do
      Factory(:activity_log, :activity_loggable => sop, :action => 'update')
      Factory(:activity_log, :activity_loggable => df, :action => 'update')
      SendPeriodicEmailsJob.new('weekly').perform
    end

    #unsubscribe to project
    put :update, :id => current_person, :receive_notifications => true, :person => {:project_subscriptions_attributes => {'0' => {:id => current_person.project_subscriptions.first.id, :project_id => proj.id, :frequency => 'weekly', :_destroy => '1'}}}
    assert_redirected_to current_person
    assert current_person.project_subscriptions.empty?

    sop.reload
    df.reload
    assert !sop.subscribed?(current_person)
    assert !df.subscribed?(current_person)
    assert current_person.receive_notifications?

    assert_emails 0 do
        Factory(:activity_log, :activity_loggable => sop, :action => 'update')
        Factory(:activity_log, :activity_loggable => df, :action => 'update')
        SendPeriodicEmailsJob.new('weekly').perform
    end
    Seek::Config.email_enabled=temp
  end

  test 'should subscribe a person to a project when assign a person to that project' do
      a_person = Factory(:person)
      project = Factory(:project)
      work_group = Factory(:work_group, :project => project)

      #assign a person to a project
      put :administer_update, :id => a_person, :person =>{:work_group_ids => [work_group.id]}

      assert_redirected_to a_person
      a_person.reload
      assert a_person.work_groups.include?(work_group)
      assert a_person.project_subscriptions.collect(&:project).include?(project)
  end

  test 'should unsubscribe a person to a project when unassign a person to that project' do
      a_person = Factory(:person)
      work_groups = a_person.work_groups
      projects = a_person.projects
      assert_equal 1, projects.count
      assert_equal 1, work_groups.count
      assert a_person.project_subscriptions.collect(&:project).include?(projects.first)

      s=Factory(:subscribable, :project_ids => projects.collect(&:id))
      SetSubscriptionsForItemJob.new(s.class.name, s.id, projects.collect(&:id)).perform
      assert s.subscribed?(a_person)

      #unassign a person to a project
      put :administer_update, :id => a_person, :person =>{:work_group_ids => []}

      assert_redirected_to a_person
      a_person.reload
      assert a_person.work_groups.empty?
      assert !a_person.project_subscriptions.collect(&:project).include?(projects.first)
      s.reload
      assert !s.subscribed?(a_person)
  end

  test 'should show subscription list to only yourself and admin' do
    a_person = Factory(:person)
    login_as(a_person.user)
    get :show, :id => a_person
    assert_response :success
    assert_select "div.foldTitle", :text => "Subscriptions", :count => 1

    logout

    login_as(:quentin)
    get :show, :id => a_person
    assert_response :success
    assert_select "div.foldTitle", :text => "Subscriptions", :count => 1
  end

  test 'should not show subscription list to people that are not yourself and admin' do
      a_person = Factory(:person)
      login_as(Factory(:user))
      get :show, :id => a_person
      assert_response :success
      assert_select "div.foldTitle", :text => "Subscriptions", :count => 0

      logout

      get :show, :id => a_person
      assert_response :success
      assert_select "div.foldTitle", :text => "Subscriptions", :count => 0
  end
end
