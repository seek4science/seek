require 'test_helper'

class OrganismsControllerTest < ActionController::TestCase
  fixtures :all
  
  include AuthenticatedTestHelper
  include RestTestCases

  include RdfTestCases
  
  def setup
    login_as(:aaron)
  end

  def rest_api_test_object
    @object=Factory(:organism,:bioportal_concept=>Factory(:bioportal_concept))
  end
  
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
  
  test "delete button disabled for associated organisms" do
    login_as(:quentin)
    y=organisms(:yeast)
    get :show,:id=>y
    assert_response :success
    assert_select "span.disabled_icon img",:count=>1
    assert_select "span.disabled_icon a",:count=>0
  end
  
  test "admin sees edit and create buttons" do
    login_as(:quentin)
    y=organisms(:human)
    get :show,:id=>y
    assert_response :success
    assert_select "a[href=?]",edit_organism_path(y),:count=>1
    assert_select "a",:text=>/Edit Organism/,:count=>1
    
    assert_select "a[href=?]",new_organism_path,:count=>1
    assert_select "a",:text=>/Add Organism/,:count=>1
        
    assert_select "a",:text=>/Delete Organism/,:count=>1
  end
  
  test "non admin does not see edit, create and delete buttons" do
    login_as(:aaron)
    y=organisms(:human)
    get :show,:id=>y
    assert_response :success
    assert_select "a[href=?]",edit_organism_path(y),:count=>0
    assert_select "a",:text=>/Edit Organism/,:count=>0
    
    assert_select "a[href=?]",new_organism_path,:count=>0
    assert_select "a",:text=>/Add Organism/,:count=>0
    
    assert_select "a",:text=>/Delete Organism/,:count=>0
  end
  
  test "delete as admin" do
    login_as(:quentin)
    o=organisms(:human)
    assert_difference('Organism.count', -1) do
      delete :destroy, :id => o
    end
    assert_redirected_to organisms_path
  end
  
  test "cannot delete as non-admin" do
    login_as(:aaron)
    o=organisms(:human)
    assert_no_difference('Organism.count') do
      delete :destroy, :id => o
    end
    refute_nil flash[:error]
  end

  test "visualise available when logged out" do
    logout
    o=Factory(:organism,:bioportal_concept=>Factory(:bioportal_concept))
    get :visualise, :id=>o
    assert_response :success
  end
  
  test "cannot delete associated organism" do
    login_as(:aaron)
    o=organisms(:yeast)
    assert_no_difference('Organism.count') do
      delete :destroy, :id => o
    end    
  end

  test "should list strains" do
    user = Factory :user
    login_as(user)
    organism = Factory :organism
    strain_a=Factory :strain,:title=>"strainA",:organism=>organism
    parent_strain=Factory :strain
    strain_b=Factory :strain,:title=>"strainB",:parent=>parent_strain,:organism=>organism


    get :show,:id=>organism
    assert_response :success
    assert_select "table.strain_list" do
      assert_select "tr",:count=>2 do
        assert_select "td > a[href=?]",strain_path(strain_a),:text=>strain_a.title
        assert_select "td > a[href=?]",strain_path(strain_b),:text=>strain_b.title
        assert_select "td > a[href=?]",strain_path(parent_strain),:text=>parent_strain.title
      end
    end

  end
  
end
