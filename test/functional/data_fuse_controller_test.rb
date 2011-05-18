require 'test_helper'

class DataFuseControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  fixtures :all

  # Replace this with your real tests.
  test "graph test" do
    login_as(Factory(:admin).user)
    get :graph_test
    assert_response :success
  end
end
