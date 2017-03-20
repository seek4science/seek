require 'test_helper'

class OauthSessionsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  test 'should get empty OAuth sessions lists' do
    user = Factory(:user)
    login_as(user)

    get :index, user_id: user.id

    assert_response :success
  end

  test "shouldn't get OAuth session list for other user" do
    user = Factory(:user)
    other_user = Factory(:user)
    login_as(other_user)

    get :index, user_id: user.id

    assert_redirected_to root_path
    assert_not_empty flash[:error]
  end

  test 'should list OAuth sessions' do
    oauth_session = Factory(:oauth_session)
    login_as(oauth_session.user)

    get :index, user_id: oauth_session.user.id

    assert_response :success
    assert_equal 1, assigns(:oauth_sessions).size
    assert_includes(assigns(:oauth_sessions), oauth_session)
  end

  test 'should delete OAuth session' do
    oauth_session = Factory(:oauth_session)
    user = oauth_session.user
    login_as(user)

    assert_difference('OauthSession.count', -1) do
      delete :destroy, user_id: user.id, id: oauth_session.id
    end

    assert_redirected_to user_oauth_sessions_path(user)
  end

  test "shouldn't delete other users' OAuth session" do
    oauth_session = Factory(:oauth_session)
    other_user = Factory(:user)
    login_as(other_user)

    assert_no_difference('OauthSession.count') do
      delete :destroy, user_id: oauth_session.user.id, id: oauth_session.id
    end

    assert_redirected_to root_path
    assert_not_empty flash[:error]
  end
end
