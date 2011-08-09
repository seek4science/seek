require 'test_helper'

class ScalesControllerTest < ActionController::TestCase
  test "index" do
    get :index
    assert_response :success
  end

  test "show" do
    scale = Factory :scale
    get :show,:id=>scale
    assert_response :success
  end

end
