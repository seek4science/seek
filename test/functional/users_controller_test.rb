require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead
  # Then, you can remove it from this and the units test.
  include AuthenticatedTestHelper

  fixtures :all

  def test_title
    get :new
    assert_select 'title', text: 'Signup', count: 1
  end

  test 'cancel registration' do
    user = FactoryBot.create :brand_new_user
    refute user.person
    login_as user
    assert_equal user.id, session[:user_id]
    assert_difference('User.count', -1) do
      post :cancel_registration
    end

    assert_redirected_to :root
    assert_nil session[:user_id]
  end

  test 'whoami_no_login' do
    get :whoami, format: :json
    assert_response :not_found
  end

  test 'whoami_login' do
    person = FactoryBot.create :person

    login_as person.user

    get :whoami, format: :json
    assert_response :redirect
    assert_redirected_to person_path(person)

  end

  test 'cancel registration doesnt destroy user with profile' do
    person = FactoryBot.create :person

    login_as person.user
    assert_equal person.user.id, session[:user_id]
    assert_no_difference('User.count') do
      post :cancel_registration
    end

    assert_redirected_to :root
    assert_equal person.user.id, session[:user_id]
  end

  def test_activation_required_link
    get :activation_required
    assert_response :success
  end

  test 'should destroy only by admin' do
    user_without_profile = FactoryBot.create :brand_new_user
    user = FactoryBot.create :user
    login_as user
    assert_difference('User.count', 0) do
      delete :destroy, params: { id: user_without_profile }
    end
    logout
    admin = FactoryBot.create(:user, person_id: FactoryBot.create(:admin).id)
    login_as admin
    assert_difference('User.count', -1) do
      delete :destroy, params: { id: user_without_profile }
    end
  end

  test 'should not destroy user with profile' do
    person = FactoryBot.create :person
    admin = FactoryBot.create(:user, person_id: FactoryBot.create(:admin).id)
    login_as admin
    assert_no_difference('User.count') do
      delete :destroy, params: { id: person.user }
    end
  end

  test 'resend activation email only by admin' do
    person = FactoryBot.create(:person)
    user = FactoryBot.create :brand_new_user, person: person
    assert !user.active?
    login_as FactoryBot.create(:user)
    assert_enqueued_emails(0) do
      assert_no_difference('ActivationEmailMessageLog.count') do
        post :resend_activation_email, params: { id: user }
      end      
    end
    
    assert_empty person.activation_email_logs

    assert_not_nil flash[:error]
    flash.clear
    logout
    admin = FactoryBot.create(:user, person_id: FactoryBot.create(:admin).id)
    login_as admin
    assert_enqueued_emails(1) do
      assert_difference('ActivationEmailMessageLog.count') do
        post :resend_activation_email, params: { id: user }
      end
    end
    assert_nil flash[:error]
    assert_equal 1,person.activation_email_logs.count
  end

  test 'only admin can bulk_destroy' do
    user1 = FactoryBot.create :user
    user2 = FactoryBot.create :user
    admin = FactoryBot.create(:user, person_id: FactoryBot.create(:admin).id)
    login_as admin
    assert_difference('User.count', -1) do
      post :bulk_destroy, params: { ids: [user1.id] }
    end

    logout
    assert_difference('User.count', 0) do
      post :bulk_destroy, params: { ids: [user2.id] }
    end
    assert_redirected_to :root
    assert_not_nil flash[:error]
  end

  test 'bulk destroy' do
    user1 = FactoryBot.create :user
    user2 = FactoryBot.create :user
    FactoryBot.create :favourite_group, user: user1
    FactoryBot.create :favourite_group, user: user2

    admin = FactoryBot.create(:user, person_id: FactoryBot.create(:admin).id)
    login_as admin
    # destroy also dependencies
    assert_difference('User.count', -2) do
      assert_difference('FavouriteGroup.count', -2) do
        post :bulk_destroy, params: { ids: [user1.id, user2.id] }
      end
    end
  end

  test 'bulk destroy only ids in params' do
    user1 = FactoryBot.create :user
    user2 = FactoryBot.create :user
    FactoryBot.create :favourite_group, user: user1
    FactoryBot.create :favourite_group, user: user2

    admin = FactoryBot.create(:user, person_id: FactoryBot.create(:admin).id)
    login_as admin
    # destroy also dependencies
    assert_difference('User.count', -1) do
      assert_difference('FavouriteGroup.count', -1) do
        post :bulk_destroy, params: { ids: [user1.id] }
      end
    end
  end

  def test_system_message_on_signup_no_users
    get :new
    assert_response :success
    assert_select 'div.alert', count: 0

    User.destroy_all
    get :new
    assert_response :success
    assert_select 'div.alert', count: 1
  end

  def test_should_allow_signup
    assert_difference 'User.count' do
      create_user
      assert_response :redirect
    end
  end

  def test_should_require_login_on_signup
    assert_no_difference 'User.count' do
      create_user(login: nil)
      assert assigns(:user).errors[:login]
    end
  end

  def test_should_require_password_on_signup
    assert_no_difference 'User.count' do
      create_user(password: nil)
      assert assigns(:user).errors[:password]
    end
  end

  def test_should_require_password_confirmation_on_signup
    assert_no_difference 'User.count' do
      create_user(password_confirmation: nil)
      assert assigns(:user).errors[:password_confirmation]
    end
  end

  test 'should activate user' do
    user = FactoryBot.create(:not_activated_person).user
    refute user.active?

    #make some logs
    ActivationEmailMessageLog.log_activation_email(user.person)
    ActivationEmailMessageLog.log_activation_email(user.person)

    assert_equal 2, ActivationEmailMessageLog.activation_email_logs(user.person).count

    assert_difference('ActivationEmailMessageLog.count',-2) do
      get :activate, params: { activation_code: user.activation_code }
    end

    assert_empty ActivationEmailMessageLog.activation_email_logs(user.person)

    assert_redirected_to person_path(user.person)
    refute_nil flash[:notice]
    assert User.find(user.id).active?
  end

  def test_should_not_activate_user_without_key
    get :activate
    assert_nil flash[:notice]
  end

  def test_should_not_activate_user_with_blank_key
    get :activate, params: { activation_code: '' }
    assert_nil flash[:notice]
  end

  def test_can_edit_self
    login_as :quentin
    get :edit, params: { id: users(:quentin) }
    assert_response :success
    # TODO: is there a better way to test the layout used?
    assert_select '#navbar' # check its using the right layout
  end

  def test_cant_edit_some_else
    login_as :quentin
    get :edit, params: { id: users(:aaron) }
    assert_redirected_to root_url
  end

  def test_associated_with_person
    u = FactoryBot.create(:brand_new_user)
    login_as u
    assert_nil u.person
    p = FactoryBot.create(:brand_new_person)
    post :update, params: { id: u.id, user: { id: u.id, person_id: p.id, email: p.email } }
    assert_nil flash[:error]
    assert_equal p, User.find(u.id).person
  end

  def test_update_password
    login_as :quentin
    u = users(:quentin)
    pwd = 'b' * User::MIN_PASSWORD_LENGTH
    post :update, params: { id: u.id, user: { id: u.id, password: pwd, password_confirmation: pwd } }
    assert_nil flash[:error]
    assert User.authenticate('quentin', pwd)
  end

  test 'reset code cleared after updating password' do
    user = FactoryBot.create(:user)
    user.reset_password
    user.save!
    login_as(user)
    pwd = 'a' * User::MIN_PASSWORD_LENGTH
    post :update, params: { id: user.id, user: { id: user.id, password: pwd, password_confirmation: pwd } }
    user.reload
    assert_nil user.reset_password_code
    assert_nil user.reset_password_code_until
  end

  test 'admin can impersonate' do
    login_as :quentin
    assert User.current_user, users(:quentin)

    get :impersonate, params: { id: users(:aaron) }

    assert_redirected_to root_path
    assert User.current_user, users(:aaron)
  end

  test 'admin redirected back impersonating non-existent user' do
    login_as :quentin
    assert User.current_user, users(:quentin)

    get :impersonate, params: { id: (User.last.id + 1) }

    assert_redirected_to admin_path
    assert User.current_user, users(:quentin)
    assert flash[:error]
  end

  test 'non admin cannot impersonate' do
    login_as :aaron
    assert User.current_user, users(:aaron)

    get :impersonate, params: { id: users(:quentin) }

    assert flash[:error]
    assert User.current_user, users(:aaron)
  end

  test 'should handle no current_user when edit user' do
    logout
    get :edit, params: { id: users(:aaron), user: {} }
    assert_redirected_to :root
    assert_not_nil flash[:error]
  end

  test 'reset password with valid code' do
    user = FactoryBot.create(:user)
    user.reset_password
    user.save!
    refute_nil(user.reset_password_code)
    refute_nil(user.reset_password_code_until)
    get :reset_password, params: { reset_code: user.reset_password_code }
    assert_redirected_to edit_user_path(user)
    assert_equal 'You can change your password here', flash[:notice]
    assert_nil flash[:error]
  end

  test 'reset password with invalid code' do
    get :reset_password, params: { reset_code: 'xxx' }
    assert_redirected_to root_path
    assert_nil flash[:notice]
    refute_nil flash[:error]
    assert_equal 'Invalid password reset code', flash[:error]
  end

  test 'reset password with no code' do
    get :reset_password
    assert_redirected_to root_path
    assert_nil flash[:notice]
    refute_nil flash[:error]
    assert_equal 'Invalid password reset code', flash[:error]
  end

  test 'reset password with expired code' do
    user = FactoryBot.create(:user)
    user.reset_password
    user.reset_password_code_until = 5.days.ago
    user.save!
    get :reset_password, params: { reset_code: user.reset_password_code }
    assert_redirected_to root_path
    assert_nil flash[:notice]
    refute_nil flash[:error]
    assert_equal 'Your password reset code has expired', flash[:error]
  end

  test 'terms and conditions checkbox' do
    with_config_value :terms_enabled,true do
      assert User.any?
      get :new
      assert_response :success
      assert_select "form.new_user input#tc_agree[type=checkbox]", count:1
      assert_select "form.new_user input.btn[type=submit][disabled]", count:1
      assert_select "form.new_user input.btn[type=submit]:not([disabled])", count:0
    end
  end

  # First user is the admin user that sets it up, so no T & C's to agree to
  test 'no terms and conditions checkbox for first user' do
    with_config_value :terms_enabled,true do
      User.destroy_all
      refute User.any?
      get :new
      assert_response :success
      assert_select "form.new_user input#tc_agree[type=checkbox]", count:0
      assert_select "form.new_user input.btn[type=submit][disabled]", count:0
      assert_select "form.new_user input.btn[type=submit]:not([disabled])", count:1
    end
  end

  test "no terms and conditions if disabled" do
    with_config_value :terms_enabled,false do
      assert User.any?
      get :new
      assert_response :success
      assert_select "form.new_user input#tc_agree[type=checkbox]", count:0
      assert_select "form.new_user input.btn[type=submit][disabled]", count:0
      assert_select "form.new_user input.btn[type=submit]:not([disabled])", count:1
    end
  end

  test 'admin can activate user' do
    person = FactoryBot.create(:not_activated_person)
    user = person.user
    refute user.active?
    me = FactoryBot.create(:admin).user
    login_as me

    assert_enqueued_email_with(Mailer, :welcome, args: [user]) do
      post :activate_other, params: { id: user }
    end

    assert_redirected_to person_path(person)
    assert user.reload.active?
    assert_equal me, User.current_user
  end

  test 'non-admin cannot activate user' do
    person = FactoryBot.create(:not_activated_person)
    user = person.user
    refute user.active?
    me = FactoryBot.create(:person).user
    login_as me

    assert_no_enqueued_emails do
      post :activate_other, params: { id: user }
    end

    assert_redirected_to :root
    refute user.reload.active?
    assert flash[:error].include?('Admin rights')
    assert_equal me, User.current_user
  end

  test 'nothing happens when admin activates active user' do
    person = FactoryBot.create(:person)
    user = person.user
    assert user.active?
    me = FactoryBot.create(:admin).user
    login_as me

    assert_no_enqueued_emails do
      post :activate_other, params: { id: user }
    end

    assert_redirected_to :root
    assert user.reload.active?
    assert flash[:error].include?('already')
    assert_equal me, User.current_user
  end

  protected

  def create_user(options = {})
    pwd = 'a' * User::MIN_PASSWORD_LENGTH
    post :create, params: { user: { login: 'quire', email: 'quire@example.com',
                          password: pwd, password_confirmation: pwd }.merge(options), person: { first_name: 'fred' } }
  end
end
