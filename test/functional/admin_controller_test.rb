require 'test_helper'

class AdminControllerTest < ActionController::TestCase

  fixtures :users

  include AuthenticatedTestHelper

  test "visible to admin" do
    login_as(:quentin)
    get :show
    assert_response :success
    assert_nil flash[:error]
  end

  test "invisible to non admin" do
    login_as(:aaron)
    get :show
    assert_response :redirect
    assert_not_nil flash[:error]
  end

  

end
