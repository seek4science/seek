require "test_helper"

class SpecimensControllerTest < ActionController::TestCase

  fixtures :all
  include AuthenticatedTestHelper

  def setup
    login_as :owner_of_fully_public_policy
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:specimens)
  end
  test "should get new" do
    get :new
    assert_response :success
    assert_not_nil assigns(:specimen)

  end
  test "should create" do
    assert_difference("Specimen.count") do
      post :create, :specimen =>  {:donor_number => "running mouse NO.1",:lab_internal_number =>"Do232",:contributor => Factory(:user),:organism => Factory(:organism),:strain => Factory(:strain),:institution => Factory(:institution)}, :project_id => projects(:one).id
    end
    s = assigns(:specimen)
    assert_redirected_to specimen_path(s)
    assert_equal "running mouse NO.1", s.donor_number
  end
  test "should get show" do
    get :show, :id => Factory(:specimen, :donor_number=>"running mouse NO2", :policy =>policies(:editing_for_all_sysmo_users_policy))
    assert_response :success
    assert_not_nil assigns(:specimen)
  end

  test "should get edit" do
    get :edit, :id=> Factory(:specimen, :policy => policies(:editing_for_all_sysmo_users_policy))
    assert_response :success
    assert_not_nil assigns(:specimen)
  end
  test "should update" do
    specimen = Factory(:specimen, :donor_number=>"Running mouse NO3", :policy =>policies(:editing_for_all_sysmo_users_policy))
    assert_not_equal "test", specimen.donor_number
    put "update", :id=>specimen.id, :specimen =>{:donor_number =>"test"}
    s = assigns(:specimen)
    assert_redirected_to specimen_path(s)
    assert_equal "test", s.donor_number
  end
  test "unauthorized users cannot add new specimens" do
    login_as Factory(:user)
    get :new
    assert_response :redirect
  end
  test "unauthorized user cannot update" do
    login_as Factory(:user)
    s = Factory(:specimen, :policy => Factory(:private_policy))

    put :update, :id=> s.id, :specimen =>{:donor_number =>"test"}
    assert_redirected_to specimen_path(s)
    assert flash[:error]
  end
end