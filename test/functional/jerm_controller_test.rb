require 'test_helper'

class JermControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  
  fixtures :all

  test "index" do
    login_as(:quentin)
    get :index
    assert_response :success
  end

  test "no index for non-admin" do
    login_as(:aaron)
    get :index
    assert_redirected_to :root
  end

  
end
