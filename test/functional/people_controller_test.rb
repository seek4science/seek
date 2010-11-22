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
    assert_select "title", :text=>/Sysmo SEEK People.*/, :count=>1
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
  
  def test_first_regsitered_person_is_admin
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
  
  def test_second_regsitered_person_is_not_admin
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
    assert_redirected_to root_path
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
  
  def test_admin_can_is_admin_flag
    login_as(:quentin)
    p=people(:fred)
    assert !p.is_admin?
    put :update, :id=>p.id, :person=>{:id=>p.id, :is_admin=>true, :email=>"ssfdsd@sdfsdf.com"}
    assert_redirected_to person_path(p)
    assert_nil flash[:error]
    p.reload
    assert p.is_admin?
  end
  
  def test_non_admin_cant_is_admin_flag
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
  
  def test_tags_updated_correctly
    p=people(:aaron_person)
    p.expertise_list="one,two,three"
    p.tool_list="four"
    assert p.save
    assert_equal ["one","two","three"],p.expertise_list
    assert_equal ["four"],p.tool_list
    
    p=Person.find(p.id)
    assert_equal ["one","two","three"],p.expertise_list
    assert_equal ["four"],p.tool_list
    
    one=Tag.find(:first,:conditions=>{:name=>"one"})
    two=Tag.find(:first,:conditions=>{:name=>"two"})
    four=Tag.find(:first,:conditions=>{:name=>"four"})
    post :update, :id=>p.id, :person=>{}, :expertise_autocompleter_selected_ids=>[one.id,two.id],:tools_autocompleter_selected_ids=>[four.id],:tools_autocompleter_unrecognized_items=>"three"
    
    p=Person.find(p.id)
    
    assert_equal ["one","two"],p.expertise_list
    assert_equal ["four","three"],p.tool_list
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
end
