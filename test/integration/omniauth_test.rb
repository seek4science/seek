require 'test_helper'

class OmniauthTest < ActionDispatch::IntegrationTest
  # Branches to test:
  #     Identity exists - log in
  #     Identity does not exist
    #     Using LDAP
      #     SEEK user with matching login to LDAP username exists - log in and link identity
      #     SEEK user does not exist
    #     Not using LDAP, or SEEK user did not exist (Test with AAI and LDAP)
      #     User is logged in - link identity
      #     User is not logged in
        #     OmniAuth user creation allowed
          #     User with email exists - create user, log in, direct to "is this me?" page
          #     User with email does not exist - create user, log in, direct to registration page *done*
        #     OmniAuth user creation not allowed - display error

  include AuthenticatedTestHelper

  fixtures :users, :people

  def setup
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:ldap] = nil
    OmniAuth.config.mock_auth[:elixir_aai] = nil

    @ldap_mock_auth = OmniAuth::AuthHash.new({
        provider: 'ldap',
        uid: 'new_ldap_user',
        info: {
            'nickname' => 'new_ldap_user',
            'first_name' => 'new',
            'last_name' => 'ldap_user',
            'email' => 'new_ldap_user@example.com'
        }
    })

    @elixir_aai_mock_auth = OmniAuth::AuthHash.new({
        provider: 'elixir_aai',
        uid: 'new_elixir_aai_user',
        info: {
            'nickname' => 'new_elixir_aai_user',
            'first_name' => 'new',
            'last_name' => 'elixir_aai_user',
            'email' => 'new_elixir_aai_user@example.com'
        }
    })
  end

  test 'should create and activate new LDAP user' do
    OmniAuth.config.mock_auth[:ldap] = @ldap_mock_auth

    assert_difference('User.count', 1) do
      assert_difference('Identity.count', 1) do
        post omniauth_callback_path(:ldap) # With LDAP we post directly to the callback, since the form is in SEEK
        assert_redirected_to /#{register_people_path}/

        follow_redirect! # New profile
      end
    end

    assert_equal 'ldap_user', assigns(:person).last_name
    assert_equal 'new', assigns(:person).first_name
    assert_equal 'new_ldap_user@example.com', assigns(:person).email
    assert session[:user_id]
    user = User.find_by_id(session[:user_id])
    assert user
    assert user.active?
    assert_equal 1, user.identities.count
    identity = user.identities.first
    assert_equal 'ldap', identity.provider
    assert_equal 'new_ldap_user', identity.uid
    assert_match(/You have successfully registered your account, but you need to create a profile/, flash[:notice])
  end

  test 'should create and activate new ELIXIR AAI user' do
    OmniAuth.config.mock_auth[:elixir_aai] = @elixir_aai_mock_auth

    assert_difference('User.count', 1) do
      assert_difference('Identity.count', 1) do
        post omniauth_authorize_path(:elixir_aai)
        follow_redirect! # OmniAuth callback
        assert_redirected_to /#{register_people_path}/
        follow_redirect! # New profile
      end
    end

    assert_equal 'elixir_aai_user', assigns(:person).last_name
    assert_equal 'new', assigns(:person).first_name
    assert_equal 'new_elixir_aai_user@example.com', assigns(:person).email
    assert session[:user_id]
    user = User.find_by_id(session[:user_id])
    assert user
    assert user.active?
    assert_equal 1, user.identities.count
    identity = user.identities.first
    assert_equal 'elixir_aai', identity.provider
    assert_equal 'new_elixir_aai_user', identity.uid
    assert_match(/You have successfully registered your account, but you need to create a profile/, flash[:notice])
  end
end
