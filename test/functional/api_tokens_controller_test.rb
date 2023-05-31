require 'test_helper'

class ApiTokensControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  test 'should get empty API token lists' do
    user = FactoryBot.create(:user)
    login_as(user)

    get :index, params: { user_id: user.id }

    assert_response :success
  end

  test "shouldn't get API token list for other user" do
    user = FactoryBot.create(:user)
    other_user = FactoryBot.create(:user)
    login_as(other_user)

    get :index, params: { user_id: user.id }

    assert_redirected_to root_path
    assert_not_empty flash[:error]
  end

  test 'should list API tokens' do
    api_token = FactoryBot.create(:api_token)
    login_as(api_token.user)

    get :index, params: { user_id: api_token.user.id }

    assert_response :success
    assert_equal 1, assigns(:api_tokens).size
    assert_includes(assigns(:api_tokens), api_token)
  end

  test 'should create API token' do
    user = FactoryBot.create(:user)
    login_as(user)

    assert_difference('ApiToken.count', 1) do
      post :create, params: { user_id: user.id, api_token: { title: 'New API token' } }
    end

    assert_response :success

    # Should show the token in plain text
    assert_select '#token' do
      assert_select ":match('value', ?)", /[-_a-zA-Z0-9]{#{ApiToken::API_TOKEN_LENGTH}}/
    end
  end

  test 'should not create API token for other user' do
    user = FactoryBot.create(:user)
    other_user = FactoryBot.create(:user)
    login_as(user)

    assert_no_difference('ApiToken.count') do
      post :create, params: { user_id: other_user.id, api_token: { title: 'New API token' } }
    end

    assert_redirected_to root_path
    assert_not_empty flash[:error]
  end

  test 'should delete API token' do
    api_token = FactoryBot.create(:api_token)
    user = api_token.user
    login_as(user)

    assert_difference('ApiToken.count', -1) do
      delete :destroy, params: { user_id: user.id, id: api_token.id }
    end

    assert_redirected_to user_api_tokens_path(user)
  end

  test "shouldn't delete other users' API token" do
    api_token = FactoryBot.create(:api_token)
    other_user = FactoryBot.create(:user)
    login_as(other_user)

    assert_no_difference('ApiToken.count') do
      delete :destroy, params: { user_id: other_user.id, id: api_token.id }
    end

    assert_response :not_found
  end
end
