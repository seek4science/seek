require 'test_helper'

class ModelsControllerTest < ActionController::TestCase

  fixtures :models,:recomended_model_environments
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:models)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create model" do
    assert_difference('Model.count') do
      post :create, :model => { }
    end

    assert_redirected_to model_path(assigns(:model))
  end

  test "should show model" do
    get :show, :id => models(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => models(:one).id
    assert_response :success
  end

  test "should update model" do
    put :update, :id => models(:one).id, :model => { }
    assert_redirected_to model_path(assigns(:model))
  end

  test "should destroy model" do
    assert_difference('Model.count', -1) do
      delete :destroy, :id => models(:one).id
    end

    assert_redirected_to models_path
  end
end
