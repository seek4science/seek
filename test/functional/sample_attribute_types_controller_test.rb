require 'test_helper'

class SampleAttributeTypesControllerTest < ActionController::TestCase
  setup do
    @sample_attribute_type = sample_attribute_types(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:sample_attribute_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create sample_attribute_type" do
    assert_difference('SampleAttributeType.count') do
      post :create, sample_attribute_type: {  }
    end

    assert_redirected_to sample_attribute_type_path(assigns(:sample_attribute_type))
  end

  test "should show sample_attribute_type" do
    get :show, id: @sample_attribute_type
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @sample_attribute_type
    assert_response :success
  end

  test "should update sample_attribute_type" do
    put :update, id: @sample_attribute_type, sample_attribute_type: {  }
    assert_redirected_to sample_attribute_type_path(assigns(:sample_attribute_type))
  end

  test "should destroy sample_attribute_type" do
    assert_difference('SampleAttributeType.count', -1) do
      delete :destroy, id: @sample_attribute_type
    end

    assert_redirected_to sample_attribute_types_path
  end
end
