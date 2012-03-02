require 'test_helper'
require 'users_controller'

# Re-raise errors caught by the controller.
class UsersController; def rescue_action(e) raise e end; end

class UsersControllerTest < ActionController::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead
  # Then, you can remove it from this and the units test.
  include AuthenticatedTestHelper
  
  fixtures :all
  
  def setup
    @controller = UsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_title
    get :new
    assert_select "title",:text=>/The Sysmo SEEK.*/, :count=>1
  end
  
  def test_activation_required_link
    get :activation_required
    assert_response :success
  end
  
  def test_system_message_on_signup_no_users
    get :new
    assert_response :success
    assert_select "p.system_message",:count=>0
    
    User.destroy_all
    get :new
    assert_response :success
    assert_select "p.system_message",:count=>1
  end
  
  def test_should_allow_signup
    assert_difference 'User.count' do
      create_user
      assert_response :redirect
    end
  end
  
  def test_should_require_login_on_signup
    assert_no_difference 'User.count' do
      create_user(:login => nil)
      assert assigns(:user).errors.on(:login)
      assert_response :redirect
    end
  end
  
  def test_should_require_password_on_signup
    assert_no_difference 'User.count' do
      create_user(:password => nil)
      assert assigns(:user).errors.on(:password)
      assert_response :redirect
    end
  end
  
  def test_should_require_password_confirmation_on_signup
    assert_no_difference 'User.count' do
      create_user(:password_confirmation => nil)
      assert assigns(:user).errors.on(:password_confirmation)
      assert_response :redirect
    end
  end
  
  def test_should_not_require_email_on_signup
    assert_difference 'User.count' do
      create_user(:email => nil)
      assert_response :redirect
    end
  end  
  
  def test_should_activate_user
    assert !users(:aaron).active?
    get :activate, :activation_code => users(:aaron).activation_code
    assert_redirected_to person_path(people(:aaron_person))
    assert_not_nil flash[:notice]
    assert User.find(users(:aaron).id).active?    
  end
  
  def test_should_not_activate_user_without_key
    get :activate
    assert_nil flash[:notice]
  rescue ActionController::RoutingError
    # in the event your routes deny this, we'll just bow out gracefully.
  end
  
  def test_should_not_activate_user_with_blank_key
    get :activate, :activation_code => ''
    assert_nil flash[:notice]
  rescue ActionController::RoutingError
    # well played, sir
  end
  
  def test_can_edit_self
    login_as :quentin
    get :edit, :id=>users(:quentin)
    assert_response :success
    #TODO: is there a better way to test the layout used?
    assert_select "div#myexp_sidebar" #check its using the right layout
  end
  
  def test_cant_edit_some_else
    login_as :quentin
    get :edit, :id=>users(:aaron)
    assert_redirected_to root_url
  end  
  
  def test_associated_with_person
    login_as :part_registered
    u=users(:part_registered)
    p=people(:not_registered)
    post :update, :id=>u.id,:user=>{:id=>u.id,:person_id=>p.id}
    assert_nil flash[:error]
    assert_equal p,User.find(u.id).person
  end
  
  def test_assocated_with_pal
    login_as :part_registered
    u=users(:part_registered)
    
    p=people(:pal)
    post :update, :id=>u.id,:user=>{:id=>u.id,:person_id=>p.id}
    assert_nil flash[:error]
    u=User.find(u.id)
    assert_equal p.id,u.person.id
  end
  
  def test_update_password
    login_as :quentin
    u=users(:quentin)
    post :update, :id=>u.id, :user=>{:id=>u.id,:password=>"mmmmm",:password_confirmation=>"mmmmm"}
    assert_nil flash[:error]
    assert User.authenticate("quentin","mmmmm")
  end
  
  def admin_can_impersonate
    login_as :quentin
    assert self.current_user, users(:quentin)
    get :impersonate, :id=>users(:aaron)
    assert self.current_user, users(:aaron)
  end
  
  def non_admin_cannot_impersonate
    login_as :aaron
    assert self.current_user, users(:aaron)  
    get :impersonate, :id=>users(:quentin)
    assert flash[:error]
    assert self.current_user, users(:aaron)    
  end

  test 'should handle no current_user when edit user' do
    logout
    get :edit, :id => users(:aaron), :user => {}
    assert_redirected_to :root
    assert_not_nil flash[:error]
  end

  protected
  def create_user(options = {})
    post :create, { :login => 'quire', :email => 'quire@example.com',
      :password => 'quire', :password_confirmation => 'quire' }.merge(options),:person=>{:first_name=>"fred"}
  end
  
end
