require 'test_helper'

class ModelsControllerTest < ActionController::TestCase

  fixtures :all

  include AuthenticatedTestHelper
  
  def setup
    login_as(:model_owner)
  end
  
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
      post :create, :model => valid_model, :sharing=>valid_sharing
    end

    assert_redirected_to model_path(assigns(:model))
  end

  test "should create with preferred environment" do
    assert_difference('Model.count') do
      model=valid_model
      model[:recommended_environment_id]=recommended_model_environments(:jws).id
      post :create, :model => model, :sharing=>valid_sharing
    end

    m=assigns(:model)
    assert m
    assert_equal "JWS Online",m.recommended_environment.title
  end

  test "should show model" do
    get :show, :id => models(:teusink).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => models(:teusink).id
    assert_response :success
  end

  test "should update model" do
    put :update, :id => models(:teusink).id, :model => { }
    assert_redirected_to model_path(assigns(:model))
  end

  test "should destroy model" do
    assert_difference('Model.count', -1) do
      delete :destroy, :id => models(:teusink).id
    end

    assert_redirected_to models_path
  end



  def valid_model
    { :title=>"Test",:data=>fixture_file_upload('files/little_file.txt')}
  end

  def valid_sharing
    {
      :use_whitelist=>"0",
      :user_blacklist=>"0",
      :sharing_scope=>Policy::ALL_REGISTERED_USERS,
      :permissions=>{:contributor_types=>ActiveSupport::JSON.encode("Person"),:values=>ActiveSupport::JSON.encode({})}
    }
  end
  
end
