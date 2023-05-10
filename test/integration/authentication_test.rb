require 'test_helper'

class AuthenticationTest < ActionDispatch::IntegrationTest
  def setup
    @user = FactoryBot.create(:user,
                    login: 'my-user',
                    password: 'my-password',
                    password_confirmation: 'my-password')
    api_token = @user.api_tokens.create!(title: 'my token')
    @token = api_token.token
    @user.person.update_column(:email, 'my-user@example.com')

    @document = FactoryBot.create(:private_document, contributor: @user.person)
  end

  test 'authenticate using HTTP basic' do
    get document_path(@document), headers: { 'Authorization' => basic_auth('my-user', 'my-password') }

    assert_response :success
    assert_equal @user.id, session[:user_id]
  end

  test 'authenticate using HTTP basic with email instead of login' do
    get document_path(@document), headers: { 'Authorization' => basic_auth('my-user@example.com', 'my-password') }

    assert_response :success
    assert_equal @user.id, session[:user_id]
  end

  test 'authenticate using API token' do
    get document_path(@document), headers: { 'Authorization' => token_auth(@token) }

    assert_response :success
    assert_equal @user.id, session[:user_id]
  end

  test 'authenticate using session' do
    post '/session', params: { login: 'my-user', password: 'my-password' }
    assert_equal @user.id, session[:user_id]

    get document_path(@document)
    assert_response :success
  end

  test 'authenticate using cookie (auth token)' do
    @user.remember_me
    cookies[:auth_token] = @user.remember_token

    get document_path(@document)

    assert_response :success
    assert_equal @user.id, session[:user_id]
  end

  test 'do not authenticate using expired cookie (auth token)' do
    @user.remember_me
    cookies[:auth_token] = @user.remember_token
    @user.update_column(:remember_token_expires_at, 3.months.ago)

    get document_path(@document)

    assert_response :forbidden
    assert_nil session[:user_id]
  end

  test 'authenticate using doorkeeper with token in query params' do
    oauth_access_token = FactoryBot.create(:oauth_access_token, resource_owner_id: @user.id)

    get document_path(@document), params: { access_token: oauth_access_token.token }

    assert_response :success
    assert_equal @user.id, session[:user_id]
  end

  test 'do not authenticate using doorkeeper with expired token' do
    oauth_access_token = FactoryBot.create(:oauth_access_token, resource_owner_id: @user.id, created_at: 3.years.ago)

    get document_path(@document), headers: { 'Authorization' => bearer_auth(oauth_access_token.token) }

    assert_response :unauthorized
    assert_nil session[:user_id]
  end


  private

  def token_auth(token)
    "Token #{token}"
  end

  def bearer_auth(token)
    "Bearer #{token}"
  end

  def basic_auth(username, password)
    ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
  end
end
