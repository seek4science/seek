require 'test_helper'

class OrganismsControllerTest < ActionController::TestCase
  fixtures :all
  
  include AuthenticatedTestHelper
  
  test "admin can get edit" do
    login_as(:quentin)
    get :edit,:id=>organisms(:yeast)
    assert_response :success
    assert_nil flash[:error]
  end
  
  test "non admin cannot get edit" do
    login_as(:aaron)
    get :edit,:id=>organisms(:yeast)
    assert_response :redirect
    assert_not_nil flash[:error]
  end
  
  test "admin can update" do
    login_as(:quentin)
    y=organisms(:yeast)
    put :update,:id=>y.id,:organism=>{:title=>"fffff"}
    assert_redirected_to organism_path(y)
    assert_nil flash[:error]
    y=Organism.find(y.id)
    assert_equal "fffff",y.title
  end
  
  test "non admin cannot update" do
    login_as(:aaron)
    y=organisms(:yeast)
    put :update,:id=>y.id,:organism=>{:title=>"fffff"}
    assert_redirected_to root_path
    assert_not_nil flash[:error]
    y=Organism.find(y.id)
    assert_equal "yeast",y.title
  end
  
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
  
  test "admin sees edit and create buttons" do
    login_as(:quentin)
    y=organisms(:yeast)
    get :show,:id=>y
    assert_response :success
    assert_select "a[href=?]",edit_organism_path(y),:count=>1
    assert_select "a",:text=>/Edit Organism/,:count=>1
    
    assert_select "a[href=?]",new_organism_path,:count=>1
    assert_select "a",:text=>/Add Organism/,:count=>1
  end
  
  test "non admin does not see edit and create buttons" do
    login_as(:aaron)
    y=organisms(:yeast)
    get :show,:id=>y
    assert_response :success
    assert_select "a[href=?]",edit_organism_path(y),:count=>0
    assert_select "a",:text=>/Edit Organism/,:count=>0
    
    assert_select "a[href=?]",new_organism_path,:count=>0
    assert_select "a",:text=>/Add Organism/,:count=>0
  end
end
