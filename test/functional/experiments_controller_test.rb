require "test_helper"

class ExperimentsControllerTest < ActionController::TestCase
  fixtures :all
  include AuthenticatedTestHelper
  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    login_as Factory(:user)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:experiments)
  end

  test "should get new" do
    get :new
    assert_response :success
    assert_not_nil assigns(:experiment)
  end

  test "should create" do
    assert_difference("Experiment.count") do
      post :create, :experiment => {
          :title => "test",
          :date => Date.today,
          :description => "test for experiment",
          :project => Factory(:project),
          :institution => Factory(:institution),
          :contributor => Factory(:user),
          :sample => Factory(:sample)
      }
    end
    e = assigns(:experiment)
    assert e
    assert_redirected_to experiment_path(e)
    assert_equal "test", e.title
  end

  test "should get show" do
    e = Factory :experiment, :title =>"TEST EXPERIMENT", :policy => policies(:editing_for_all_sysmo_users_policy)
    get :show, :id => e
    assert_response :success
    assert assigns(:experiment)
    assert_select "h1", :text => "TEST EXPERIMENT", :count => 1
  end

  test "should get edit" do
    e = Factory :experiment, :policy => policies(:editing_for_all_sysmo_users_policy)
    get :edit, :id => e
    assert_response :success
    assert assigns(:experiment)
  end

  test "should update" do
    e = Factory :experiment, :title => "An experiment", :policy => policies(:editing_for_all_sysmo_users_policy)
    put "update", :id =>e, :experiment => {:title => "TEST"}, :project_id => 1
    assert assigns(:experiment)
    assert_redirected_to experiment_path(e)
  end

  test "should delete" do
    e = Factory :experiment,:contributor => User.current_user
    assert_difference("Experiment.count",-1) do
        delete "destroy", :id => e
    end
    assert_redirected_to experiments_path
  end

  test "unauthorized users cannot add new experiments" do
    user =  Factory(:user,:person => Factory(:brand_new_person))
    login_as user
    get :new
    assert !assigns(:experiment)
  end
  test "unauthorized user cannot edit experiment" do
    login_as Factory(:user,:person => Factory(:brand_new_person))
    s = Factory :experiment,:policy => policies(:editing_for_all_sysmo_users_policy)
    get :edit, :id =>s.id
    assert_response :redirect
    assert flash[:error]
  end
  test "unauthorized user cannot update experiment" do
    login_as Factory(:user,:person => Factory(:brand_new_person))
    s = Factory :experiment,:policy => policies(:editing_for_all_sysmo_users_policy)

    put :update, :id=> s.id, :experiment =>{:title =>"test"}
    assert_redirected_to experiment_path(s)
    assert flash[:error]
  end

  test "can delete experiment only when contributor is current user" do
    s =  Factory :experiment,:contributor => User.current_user
    assert_difference("Experiment.count",-1) do
      delete :destroy, :id => s.id
    end
    s = Factory :experiment,:policy => policies(:editing_for_all_sysmo_users_policy)
    assert_no_difference("Experiment.count") do
      delete :destroy, :id => s.id
    end
    assert flash[:error]
    assert_redirected_to experiments_path

    logout
    login_as Factory(:brand_new_user)
    s = Factory :experiment,:contributor => User.current_user
    assert_no_difference("Experiment.count") do
      delete :destroy, :id => s.id
    end
    assert flash[:error]
    assert_redirected_to experiments_path
  end



end