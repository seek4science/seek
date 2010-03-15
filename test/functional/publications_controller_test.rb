require 'test_helper'

class PublicationsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:publications)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create publication" do
    assert_difference('Publication.count') do
      post :create, :publication => { }
    end

    assert_redirected_to publication_path(assigns(:publication))
  end

  test "should show publication" do
    get :show, :id => publications(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => publications(:one).to_param
    assert_response :success
  end

  test "should update publication" do
    put :update, :id => publications(:one).to_param, :publication => { }
    assert_redirected_to publication_path(assigns(:publication))
  end

  test "should destroy publication" do
    assert_difference('Publication.count', -1) do
      delete :destroy, :id => publications(:one).to_param
    end

    assert_redirected_to publications_path
  end
end
