require 'test_helper'

class SessionStoreTest < ActionDispatch::IntegrationTest
  def setup
    login_as_test_user 'http://www.example.com'
  end

  test 'should timeout after 30 minutes' do

    # test initializer sets the config to 30 minutes (normal defaut is 1 hour)
    # cannot test with `with_config_value` due to being too late after the tests start

    assert_equal 30.minutes, Rails.application.config.session_options[:expire_after]
    df = FactoryBot.create :data_file, contributor: User.current_user.person
    User.current_user = nil
    get "/data_files/#{df.id}"
    assert_response :success

    travel_to(29.minutes.from_now) do
      get "/data_files/#{df.id}"
      assert_response :success
    end

    travel_to(60.minutes.from_now) do
      get "/data_files/#{df.id}"
      assert_response :forbidden
    end

    # check there is a config option
    assert_equal 30.minutes, Seek::Config.session_store_timeout
    with_config_value(:session_store_timeout, 2.hours) do
      assert_equal 2.hours, Seek::Config.session_store_timeout
    end

  end

  test 'should forbid the unauthorized page' do
    data_file = FactoryBot.create :data_file, contributor: User.current_user.person
    get "/data_files/#{data_file.id}", headers: { 'HTTP_REFERER' => "http://www.example.com/data_files/#{data_file.id}" }
    assert_response :success

    logout "http://www.example.com/data_files/#{data_file.id}"
    assert_redirected_to data_file_path(data_file)
    get "/data_files/#{data_file.id}", headers: { 'HTTP_REFERER' => "http://www.example.com/data_files/#{data_file.id}" }
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

    data_file = FactoryBot.create :data_file, policy: FactoryBot.create(:public_policy)
    get "/data_files/#{data_file.id}"
    assert_response :success

    login_as_test_user "/data_files/#{data_file.id}"
    assert_redirected_to data_file_path(data_file)
  end

  test 'should go to last visited page(except search) after browsing a forbidden page, accessible page, then login' do
    with_config_value :internal_help_enabled, true do
      data_file = FactoryBot.create :data_file, contributor: User.current_user.person

      logout 'http://www.example.com/'
      get "/data_files/#{data_file.id}", headers: { 'HTTP_REFERER' => "http://www.example.com/data_files/#{data_file.id}" }
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
    User.authenticate('test', generate_user_password) || FactoryBot.create(:user, login: 'test')
  end

  def login_as_test_user(referer)
    User.current_user = test_user
    post '/session', params: { login: test_user.login, password: generate_user_password }, headers: { 'HTTP_REFERER' => referer }
  end

  def logout(referer)
    delete '/session', headers: { 'HTTP_REFERER' => referer }
    User.current_user = nil
  end
end
