require File.dirname(__FILE__) + '/../test_helper'
require 'users_controller'

# Re-raise errors caught by the controller.
class UsersController; def rescue_action(e) raise e end; end

class UsersControllerTest < ActionController::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead
  # Then, you can remove it from this and the units test.
  include AuthenticatedTestHelper

  fixtures :users,:people

  def setup
    @controller = UsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_title
    get :new
    assert_select "title",:text=>/Sysmo SEEK.*/, :count=>1
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
      assert_response :success
    end
  end

  def test_should_require_password_on_signup
    assert_no_difference 'User.count' do
      create_user(:password => nil)
      assert assigns(:user).errors.on(:password)
      assert_response :success
    end
  end

  def test_should_require_password_confirmation_on_signup
    assert_no_difference 'User.count' do
      create_user(:password_confirmation => nil)
      assert assigns(:user).errors.on(:password_confirmation)
      assert_response :success
    end
  end

  def test_should_not_require_email_on_signup
    assert_difference 'User.count' do
      create_user(:email => nil)
      assert_response :redirect
    end
  end
  
  #  def test_should_sign_up_user_with_activation_code
  #    create_user
  #    assigns(:user).reload
  #    assert_not_nil assigns(:user).activation_code
  #  end

  def test_should_activate_user
    assert_nil User.authenticate('aaron', 'test')
    get :activate, :activation_code => users(:aaron).activation_code
    assert_redirected_to person_path(people(:two))
    assert_not_nil flash[:notice]
    assert_equal users(:aaron), User.authenticate('aaron', 'test')
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

    #check fixture
    assert !u.can_edit_projects?
    assert !u.can_edit_institutions?

    p=people(:pal)
    post :update, :id=>u.id,:user=>{:id=>u.id,:person_id=>p.id}
    assert_nil flash[:error]
    u=User.find(u.id)

    assert u.can_edit_projects?
    assert u.can_edit_institutions?
  end

  def test_update_password
    login_as :quentin
    u=users(:quentin)
    post :update, :id=>u.id, :user=>{:id=>u.id,:password=>"mmmmm",:password_confirmation=>"mmmmm"}
    assert_nil flash[:error]
    assert User.authenticate("quentin","mmmmm")
  end

  protected
  def create_user(options = {})
    post :create, :user => { :login => 'quire', :email => 'quire@example.com',
      :password => 'quire', :password_confirmation => 'quire' }.merge(options),:person=>{:first_name=>"fred"}
  end
end
