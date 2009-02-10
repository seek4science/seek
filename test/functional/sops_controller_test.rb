require 'test_helper'

class SopsControllerTest < ActionController::TestCase
  
  fixtures :sops, :assets, :content_blobs, :people, :users
  
  include AuthenticatedTestHelper
  def setup
    login_as(:quentin)
  end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:sops)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create sop" do
    assert_difference('Sop.count') do
      post :create, :sop => {:data=>fixture_file_upload('files/little_file.txt'), :title=>"test" }
    end

    assert_redirected_to sop_path(assigns(:sop))
  end

  test "should show sop" do
    get :show, :id => sops(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => sops(:one).id
    assert_response :success
  end

  test "should update sop" do
    put :update, :id => sops(:one).id, :sop => {:title=>"test" }
    assert_redirected_to sop_path(assigns(:sop))
  end

  test "should destroy sop" do
    assert_difference('Sop.count', -1) do
      delete :destroy, :id => sops(:one).id
    end

    assert_redirected_to sops_path
  end
end
