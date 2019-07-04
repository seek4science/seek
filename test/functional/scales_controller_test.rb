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

  test 'search' do
    get :search, xhr: true, params: { scale_type: 'organism' }
    assert_response :success
  end
end
