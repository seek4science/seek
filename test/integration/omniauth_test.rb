require 'test_helper'

class OmniauthTest < ActionDispatch::IntegrationTest
  include AuthenticatedTestHelper

  fixtures :users, :people

  def setup
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:ldap] = nil
    OmniAuth.config.mock_auth[:elixir_aai] = nil
    OmniAuth.config.mock_auth[:github] = nil

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

    @github_mock_auth = OmniAuth::AuthHash.new({
        provider: 'github',
        uid: 'new_github_user',
        info: {
            'nickname' => 'new_github_user',
            'name' => 'New Githubuser',
            'email' => 'new_github_user@example.com'
        }
    })
  end

  # This test is to support the legacy LDAP integration that matched users having the same SEEK and LDAP usernames
  test 'should authenticate existing LDAP user without identity' do
    OmniAuth.config.mock_auth[:ldap] = @ldap_mock_auth
    existing_user = Factory(:user, login: 'new_ldap_user')

    assert_difference('User.count', 0) do
      assert_difference('Identity.count', 1) do
        post omniauth_callback_path(:ldap)
        assert_redirected_to root_path
      end
    end

    assert_equal existing_user.id, session[:user_id]
  end

  test 'should authenticate existing LDAP user with identity' do
    OmniAuth.config.mock_auth[:ldap] = @ldap_mock_auth
    existing_user = Factory(:user, login: 'new_ldap_user')
    existing_user.identities.create!(uid: 'new_ldap_user', provider: 'ldap')

    assert_difference('User.count', 0) do
      assert_difference('Identity.count', 0) do
        post omniauth_callback_path(:ldap)
        assert_redirected_to root_path
      end
    end

    assert_equal existing_user.id, session[:user_id]
  end

  test 'should not authenticate LDAP user if omniauth disabled' do
    OmniAuth.config.mock_auth[:ldap] = @ldap_mock_auth
    existing_user = Factory(:user, login: 'new_ldap_user')
    existing_user.identities.create!(uid: 'new_ldap_user', provider: 'ldap')

    with_config_value(:omniauth_enabled, false) do
      assert_difference('User.count', 0) do
        assert_difference('Identity.count', 0) do
          post omniauth_callback_path(:ldap)
          assert_redirected_to login_path
        end
      end
    end

    assert_nil session[:user_id]
  end

  test 'should not authenticate LDAP user if LDAP omniauth disabled' do
    OmniAuth.config.mock_auth[:ldap] = @ldap_mock_auth
    existing_user = Factory(:user, login: 'new_ldap_user')
    existing_user.identities.create!(uid: 'new_ldap_user', provider: 'ldap')

    with_config_value(:omniauth_enabled, true) do
      with_config_value(:omniauth_ldap_enabled, false) do
        assert_difference('User.count', 0) do
          assert_difference('Identity.count', 0) do
            post omniauth_callback_path(:ldap)
            assert_redirected_to login_path
          end
        end
      end
    end

    assert_nil session[:user_id]
  end

  test 'should authenticate existing ELIXIR AAI user if LDAP disabled' do
    OmniAuth.config.mock_auth[:elixir_aai] = @elixir_aai_mock_auth
    OmniAuth.config.mock_auth[:ldap] = @ldap_mock_auth
    existing_user = Factory(:user, login: 'bob')
    existing_user.identities.create!(uid: 'new_elixir_aai_user', provider: 'elixir_aai')
    existing_user.identities.create!(uid: 'new_ldap_user', provider: 'ldap')

    with_config_value(:omniauth_enabled, true) do
      with_config_value(:omniauth_ldap_enabled, false) do
        with_config_value(:omniauth_elixir_aai_enabled, true) do
          # LDAP
          post omniauth_callback_path(:ldap)
          assert_redirected_to login_path
          assert_nil session[:user_id]

          # AAI
          post omniauth_authorize_path(:elixir_aai)
          follow_redirect!
          assert_redirected_to root_path
          assert_equal existing_user.id, session[:user_id]
        end
      end
    end
  end

  test 'should link LDAP identity with logged-in user' do
    OmniAuth.config.mock_auth[:ldap] = @ldap_mock_auth
    existing_user = Factory(:user, login: 'some_user')
    post '/session', params: { login: existing_user.login, password: generate_user_password }

    assert_empty existing_user.identities
    assert_equal existing_user.id, session[:user_id]

    assert_difference('User.count', 0) do
      assert_difference('Identity.count', 1) do
        post omniauth_callback_path(:ldap)
        assert_redirected_to user_identities_path(existing_user)
      end
    end

    assert_equal existing_user.id, session[:user_id]
    assert_equal 1, existing_user.reload.identities.length
    identity = existing_user.identities.first
    assert_equal 'new_ldap_user', identity.uid
    assert_equal 'ldap', identity.provider
  end

  test 'should create and activate new LDAP user' do
    OmniAuth.config.mock_auth[:ldap] = @ldap_mock_auth

    assert_difference('User.count', 1) do
      assert_difference('Identity.count', 1) do
        post omniauth_callback_path(:ldap) # With LDAP we post directly to the callback, since the form is in SEEK
        assert_redirected_to(/#{register_people_path}/)

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

  test 'should create new LDAP user with pre-made profile and show "Is this you?"' do
    OmniAuth.config.mock_auth[:ldap] = @ldap_mock_auth
    profile = Factory(:brand_new_person, email: 'new_ldap_user@example.com')

    assert_difference('User.count', 1) do
      assert_difference('Identity.count', 1) do
        post omniauth_callback_path(:ldap)
        assert_redirected_to(/#{register_people_path}/)

        follow_redirect!

        assert_select 'h1', text: 'Is this you?'
        assert_select "#user_person_id[value=?]", profile.id.to_s
        assert_select "#user_email[value=?]", profile.email
      end
    end
  end

  test 'should create and activate new ELIXIR AAI user' do
    OmniAuth.config.mock_auth[:elixir_aai] = @elixir_aai_mock_auth

    assert_difference('User.count', 1) do
      assert_difference('Identity.count', 1) do
        post omniauth_authorize_path(:elixir_aai)
        follow_redirect! # OmniAuth callback
        assert_redirected_to(/#{register_people_path}/)
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

  test 'should not create new LDAP user if setting does not allow' do
    OmniAuth.config.mock_auth[:ldap] = @ldap_mock_auth

    with_config_value(:omniauth_user_create, false) do
      assert_difference('User.count', 0) do
        assert_difference('Identity.count', 0) do
          post omniauth_callback_path(:ldap) # With LDAP we post directly to the callback, since the form is in SEEK
          assert_redirected_to login_path

          assert_nil session[:user_id]
          assert_match(/does not have a .+ account/, flash[:error])
        end
      end
    end
  end

  test 'should create but not activate new LDAP user if setting does not allow' do
    OmniAuth.config.mock_auth[:ldap] = @ldap_mock_auth

    with_config_value(:omniauth_user_activate, false) do
      assert_difference('User.count', 1) do
        assert_difference('Identity.count', 1) do
          post omniauth_callback_path(:ldap)
          assert_redirected_to(/#{register_people_path}/)

          assert session[:user_id]
          user = User.find_by_id(session[:user_id])
          assert user
          refute user.active?
        end
      end
    end
  end

  test 'should authenticate ELIXIR AAI user and redirect to path stored in state' do
    OmniAuth.config.mock_auth[:elixir_aai] = @elixir_aai_mock_auth
    existing_user = Factory(:user, login: 'bob')
    existing_user.identities.create!(uid: 'new_elixir_aai_user', provider: 'elixir_aai')

    with_config_value(:omniauth_enabled, true) do
      with_config_value(:omniauth_elixir_aai_enabled, true) do
        post omniauth_authorize_path(:elixir_aai, state: 'return_to:/sops')
        follow_redirect!
        assert_redirected_to sops_path
        assert_equal existing_user.id, session[:user_id]
      end
    end
  end

  test 'should create and activate new GitHub user' do
    OmniAuth.config.mock_auth[:github] = @github_mock_auth

    assert_difference('User.count', 1) do
      assert_difference('Identity.count', 1) do
        post omniauth_authorize_path(:github)
        follow_redirect! # OmniAuth callback
        assert_redirected_to(/#{register_people_path}/)
        follow_redirect! # New profile
      end
    end

    assert_equal 'Githubuser', assigns(:person).last_name
    assert_equal 'New', assigns(:person).first_name
    assert_equal 'new_github_user@example.com', assigns(:person).email
    assert session[:user_id]
    user = User.find_by_id(session[:user_id])
    assert user
    assert user.active?
    assert_equal 1, user.identities.count
    identity = user.identities.first
    assert_equal 'github', identity.provider
    assert_equal 'new_github_user', identity.uid
    assert_match(/You have successfully registered your account, but you need to create a profile/, flash[:notice])
  end
end
