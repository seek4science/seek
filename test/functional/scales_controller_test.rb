require 'test_helper'

class ScalesControllerTest < ActionController::TestCase
  test 'index' do
    get :index
    assert_response :success
  end

  test 'show' do
    scale = Factory :scale
    get :show, id: scale
    assert_response :success
  end

  test 'search and lazy load_results' do
    xml_http_request :get, :search_and_lazy_load_results, scale_type: 'organism'
    assert_response :success
  end
end
