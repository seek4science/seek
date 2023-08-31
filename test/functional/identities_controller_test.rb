require 'test_helper'

class IdentitiesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  test 'should get empty identities lists' do
    user = FactoryBot.create(:user)
    login_as(user)

    get :index, params: { user_id: user.id }

    assert_response :success
  end

  test "shouldn't get identity list for other user" do
    user = FactoryBot.create(:user)
    other_user = FactoryBot.create(:user)
    login_as(other_user)

    get :index, params: { user_id: user.id }

    assert_redirected_to root_path
    assert_not_empty flash[:error]
  end

  test 'should list identities' do
    identity = FactoryBot.create(:identity)
    login_as(identity.user)

    get :index, params: { user_id: identity.user.id }

    assert_response :success
    assert_equal 1, assigns(:identities).size
    assert_includes(assigns(:identities), identity)
  end

  test 'should delete identity' do
    identity = FactoryBot.create(:identity)
    user = identity.user
    login_as(user)

    assert_difference('Identity.count', -1) do
      delete :destroy, params: { user_id: user.id, id: identity.id }
    end

    assert_redirected_to user_identities_path(user)
  end

  test "shouldn't delete other users' identity" do
    identity = FactoryBot.create(:identity)
    other_user = FactoryBot.create(:user)
    login_as(other_user)

    assert_no_difference('Identity.count') do
      delete :destroy, params: { user_id: other_user.id, id: identity.id }
    end

    assert_response :not_found
  end
end
