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

  test "scale search" do
    xml_http_request :get,:scale_search,{:scale_type=>"organism"}
    assert_response :success
  end

end
