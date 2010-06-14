require 'test_helper'

class OrganismsControllerTest < ActionController::TestCase
  fixtures :all
  
  include AuthenticatedTestHelper
  
  test "admin can get new" do
    login_as(:quentin)
    get :new
    assert_response :success
    assert_nil flash[:error]
  end
  
  test "non admin cannot get new" do
    login_as(:aaron)
    get :new
    assert_response :redirect
    assert_not_nil flash[:error]
  end
  
  test "admin can create new organism" do
    login_as(:quentin)
    assert_difference("Organism.count") do
      post :create, :organism=>{:title=>"An organism"}
    end
    assert_not_nil assigns(:organism)
    assert_redirected_to organism_path(assigns(:organism))
  end
  
  test "non admin cannot create new organism" do
    login_as(:aaron)
    assert_no_difference("Organism.count") do
      post :create, :organism=>{:title=>"An organism"}
    end    
    assert_redirected_to root_path
    assert_not_nil flash[:error]
  end
end
