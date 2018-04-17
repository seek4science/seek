require 'test_helper'
require 'time_test_helper'

class SessionStoreTest < ActionDispatch::IntegrationTest
  def setup
    login_as_test_user 'http://www.example.com'
  end

  test 'should timeout after 1 hour' do
    assert_equal 1.hour, Rails.application.config.session_options[:expire_after]
    df = Factory :data_file, contributor: User.current_user
    User.current_user = nil
    get "/data_files/#{df.id}"
    assert_response :success

    pretend_now_is(59.minutes.from_now) do
      get "/data_files/#{df.id}"
      assert_response :success
    end

    pretend_now_is(80.minutes.from_now) do
      get "/data_files/#{df.id}"
      assert_response :forbidden
    end
  end

  test 'should forbid the unauthorized page' do
    data_file = Factory :data_file, contributor: User.current_user
    get "/data_files/#{data_file.id}", {}, 'HTTP_REFERER' => "http://www.example.com/data_files/#{data_file.id}"
    assert_response :success

    logout "http://www.example.com/data_files/#{data_file.id}"
    assert_redirected_to data_file_path(data_file)
    get "/data_files/#{data_file.id}", {}, 'HTTP_REFERER' => "http://www.example.com/data_files/#{data_file.id}"
    assert_response :forbidden

    login_as_test_user "http://www.example.com/data_files/#{data_file.id}"
    assert_redirected_to data_file_path(data_file)
    get "/data_files/#{data_file.id}"
    assert_response :success
  end

  test 'should go to last correctly visited page(except search) after login' do
    get '/sops'
    assert_response :success
    logout 'http://www.example.com/sops'

    data_file = Factory :data_file, contributor: User.current_user, policy: Factory(:public_policy)
    get "/data_files/#{data_file.id}"
    assert_response :success

    login_as_test_user "/data_files/#{data_file.id}"
    assert_redirected_to data_file_path(data_file)
  end

  test 'should go to last visited page(except search) after browsing a forbidden page, accessible page, then login' do
    with_config_value :internal_help_enabled, true do
      data_file = Factory :data_file, contributor: User.current_user

      logout 'http://www.example.com/'
      get "/data_files/#{data_file.id}", {}, 'HTTP_REFERER' => "http://www.example.com/data_files/#{data_file.id}"
      assert_response :forbidden

      get '/help'
      assert_response :success

      login_as_test_user '/help'
      assert_redirected_to '/help'
    end
  end

  test 'should go to root after logging in/out from search page' do
    logout 'http://www.example.com/search'
    assert_redirected_to :root

    login_as_test_user 'http://www.example.com/search'
    assert_redirected_to :root
  end

  private

  def test_user
    User.authenticate('test', generate_user_password) || Factory(:user, login: 'test')
  end

  def login_as_test_user(referer)
    User.current_user = test_user
    post '/session', { login: test_user.login, password: generate_user_password }, 'HTTP_REFERER' => referer
  end

  def logout(referer)
    delete '/session', {}, 'HTTP_REFERER' => referer
    User.current_user = nil
  end
end
