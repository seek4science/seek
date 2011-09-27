require 'test_helper'

class PeopleControllerTest < ActionController::TestCase
  
  fixtures :all
  
  include AuthenticatedTestHelper
  include RestTestCases
  
  def setup
    login_as(:quentin)
    @object=people(:quentin_person)
  end
  
  def test_title
    get :index
    assert_select "title", :text=>/The Sysmo SEEK People.*/, :count=>1
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
    assert_equal 0,Person.count,"There should be no people in the database"
    login_as(:part_registered)
    assert_difference('Person.count') do
      assert_difference('NotifieeInfo.count') do
        post :create, :person => {:first_name=>"test", :email=>"hghg@sdfsd.com" }
      end
    end
    assert assigns(:person)
    person = Person.find(assigns(:person).id)
    assert person.is_admin?
  end
  
  def test_second_registered_person_is_not_admin
    Person.destroy_all
    person = Person.new(:first_name=>"fred",:email=>"fred@dddd.com")
    person.save!
    assert_equal 1,Person.count,"There should be 1 person in the database"
    login_as(:part_registered)
    assert_difference('Person.count') do
      assert_difference('NotifieeInfo.count') do
        post :create, :person => {:first_name=>"test", :email=>"hghg@sdfsd.com" }
      end
    end
    assert assigns(:person)
    person = Person.find(assigns(:person).id)
    assert !person.is_admin?
  end
  
  def test_should_create_person
    assert_difference('Person.count') do
      assert_difference('NotifieeInfo.count') do
        post :create, :person => {:first_name=>"test", :email=>"hghg@sdfsd.com" }
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
        post :create, :person => {:first_name=>"test", :email=>"hghg@sdfsd.com", :work_group_ids => [work_group_id] }
      end
    end

    assert_redirected_to person_path(assigns(:person))
    assert_equal "T", assigns(:person).first_letter
    assert_equal [work_group_id], assigns(:person).work_group_ids
    assert_not_nil Person.find(assigns(:person).id).notifiee_info
  end
  
  def test_created_person_should_receive_notifications
    post :create, :person => {:first_name=>"test", :email=>"hghg@sdfsd.com" }
    p=assigns(:person)
    assert_not_nil p.notifiee_info
    assert p.notifiee_info.receive_notifications?
  end
      
  test "non_admin_should_not_create_pal" do
    login_as(:pal_user)
    assert_difference('Person.count') do
      post :create, :person => {:first_name=>"test", :is_pal=>true, :email=>"hghg@sdfsd.com" }
    end
    
    p=assigns(:person)
    assert_redirected_to person_path(p)
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

  def test_project_manager_can_edit_others
    login_as(:project_manager)
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
    assert p.notifiee_info.receive_notifications?,"should receive noticiations by default in fixtures"
    
    put :update, :id=>p.id, :person=>{:id=>p.id}
    assert !Person.find(p.id).notifiee_info.receive_notifications?
    
    put :update, :id=>p.id, :person=>{:id=>p.id},:receive_notifications=>true
    assert Person.find(p.id).notifiee_info.receive_notifications?
    
  end
  
  def test_admin_can_set_is_admin_flag
    login_as(:quentin)
    p=people(:fred)
    assert !p.is_admin?
    put :update, :id=>p.id, :person=>{:id=>p.id, :is_admin=>true, :email=>"ssfdsd@sdfsdf.com"}
    assert_redirected_to person_path(p)
    assert_nil flash[:error]
    p.reload
    assert p.is_admin?
  end
  
  def test_non_admin_cant_set__is_admin_flag
    login_as(:aaron)
    p=people(:fred)
    assert !p.is_admin?
    put :update, :id=>p.id, :person=>{:id=>p.id, :is_admin=>true, :email=>"ssfdsd@sdfsdf.com"}    
    assert_not_nil flash[:error]
    p.reload
    assert !p.is_admin?
  end
  
  def test_admin_can_set_pal_flag
    login_as(:quentin)
    p=people(:fred)
    assert !p.is_pal?
    put :update, :id=>p.id, :person=>{:id=>p.id, :is_pal=>true, :email=>"ssfdsd@sdfsdf.com"}
    assert_redirected_to person_path(p)
    assert_nil flash[:error]
    p.reload
    assert p.is_pal?
  end
  
  def test_non_admin_cant_set_pal_flag
    login_as(:aaron)
    p=people(:fred)
    assert !p.is_pal?
    put :update, :id=>p.id, :person=>{:id=>p.id, :is_pal=>true, :email=>"ssfdsd@sdfsdf.com"}    
    assert_not_nil flash[:error]
    p.reload
    assert !p.is_pal?
  end
  
  def test_cant_set_yourself_to_pal
    login_as(:aaron)
    p=people(:aaron_person)
    assert !p.is_pal?
    put :update, :id=>p.id, :person=>{:id=>p.id, :is_pal=>true, :email=>"ssfdsd@sdfsdf.com"}
    p.reload
    assert !p.is_pal?
  end
  
  def test_cant_set_yourself_to_admin
    login_as(:aaron)
    p=people(:aaron_person)
    assert !p.is_admin?
    put :update, :id=>p.id, :person=>{:id=>p.id, :is_admin=>true, :email=>"ssfdsd@sdfsdf.com"}        
    p.reload
    assert !p.is_admin?
  end
  
  def test_non_admin_cant_set_can_edit_institutions
    login_as(:aaron)
    p=people(:aaron_person)
    assert !p.can_edit_institutions?
    put :update, :id=>p.id, :person=>{:id=>p.id, :can_edit_institutions=>true, :email=>"ssfdsd@sdfsdf.com"}        
    p.reload
    assert !p.can_edit_institutions?
  end
  
  def test_non_admin_cant_set_can_edit_projects
    login_as(:aaron)
    p=people(:aaron_person)
    assert !p.can_edit_projects?
    put :update, :id=>p.id, :person=>{:id=>p.id, :can_edit_projects=>true, :email=>"ssfdsd@sdfsdf.com"}        
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
  
  def test_should_update_person
    put :update, :id => people(:quentin_person), :person => { }
    assert_redirected_to person_path(assigns(:person))
  end
  
  def test_should_not_update_somebody_else_if_not_admin
    login_as(:aaron)
    quentin=people(:quentin_person)
    put :update, :id => people(:quentin_person), :person => {:email=>"kkkkk@kkkkk.com" }    
    assert_not_nil flash[:error]
    quentin.reload
    assert_equal "quentin@email.com",quentin.email
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
    role=roles(:member)
    get :index,:role_id=>role.id
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
    person =  people(:quentin_person)
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
    data_file = Factory(:data_file, :contributor => user, :projects => [project])
    #create pi
    role = Role.find_by_name('PI')
    pi =  Factory(:person_in_project, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
    pi.group_memberships.first.roles << role
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
    data_file = Factory(:data_file, :contributor => user, :projects => [project])
    #create pal
    role = Role.find_by_name('Sysmo-DB Pal')
    pal =  Factory(:person_in_project, :group_memberships => [Factory(:group_membership, :work_group => work_group)])
    pal.group_memberships.first.roles << role
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

  test 'should retrieve the list of people who have the manage right on the item' do
    login_as(:quentin)
    user = Factory(:user)
    person = user.person
    data_file = Factory(:data_file, :contributor => user)
    people_can_manage = PeopleController.new().people_can_manage data_file, person
    assert_equal 1, people_can_manage.count
    assert_equal person.id, people_can_manage.first[0]

    new_person = Factory(:person_in_project)
    policy = data_file.policy
    policy.permissions.build(:contributor => new_person, :access_type => Policy::MANAGING)
    policy.save
    people_can_manage = PeopleController.new().people_can_manage data_file, person
    assert_equal 2, people_can_manage.count
    people_ids = people_can_manage.collect{|p| p[0]}
    assert people_ids.include? person.id
    assert people_ids.include? new_person.id
  end
end
