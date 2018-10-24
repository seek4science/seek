require 'test_helper'

class ScalesControllerTest < ActionController::TestCase
  test 'index' do
    get :index
    assert_response :success
  end

  test 'show' do
    scale = Factory :scale
    get :show, params: { id: scale }
    assert_response :success
  end

  test 'search and lazy load_results' do
    get :search_and_lazy_load_results, xhr: true, scale_type: 'organism'
    assert_response :success
  end
end
