require 'test_helper'

class TechnologyTypesControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases
  
  def setup
    login_as(:quentin)
  end

  def rest_api_test_object
    @object=technology_types(:gas_chromatography)
  end

  test "show" do
    login_as(:quentin)
    get :show,:id=>technology_types(:gas_chromatography)
    assert_response :success
  end

  test "should show manage page" do
    login_as(:quentin)
    get :manage
    assert_response :success
    assert_not_nil assigns(:technology_types)
  end  
  
  test "should also show manage page for non-admin" do
    login_as(:cant_edit)
    get :manage
    assert_response :success
    assert_not_nil assigns(:technology_types)
    #assert flash[:error]
    #assert_redirected_to root_url
  end

  test "should also show manage page for pal" do
    login_as Factory(:pal).user
    get :manage
    assert_response :success
    assert_not_nil assigns(:technology_types)
  end
  
  test "should show new" do
    login_as(:quentin)
    get :new
    assert_response :success
    assert_not_nil assigns(:technology_type)
  end
  
  test "should show edit" do
    login_as(:quentin)
    get :edit, :id=>technology_types(:technology_type_with_child).id
    assert_response :success
    assert_not_nil assigns(:technology_type)
  end
  
  test "should create" do
    login_as(:quentin)
    assert_difference("TechnologyType.count") do
      post :create,:technology_type=>{:title => "test_technology_type", :parent_id => [technology_types(:technology_type_with_child_and_assay).id]}      
    end
    technology_type = assigns(:technology_type)
    assert technology_type.valid?
    assert_equal 1,technology_type.parents.size
    assert_redirected_to manage_technology_types_path
  end
  
  test "should update title" do
    login_as(:quentin)
    technology_type = technology_types(:child_technology_type)
    put :update, :id => technology_type.id, :technology_type => {:title => "child_technology_type_a", :parent_id => technology_type.parents.collect {|p| p.id}}
    assert assigns(:technology_type)
    assert_equal "child_technology_type_a", assigns(:technology_type).title
  end
  
  test "should update parents" do
    login_as(:quentin)
    technology_type = technology_types(:child_technology_type)
    assert_equal 1,technology_type.parents.size
    put :update,:id=>technology_type.id,:technology_type=>{:title => technology_type.title, :parent_id => (technology_type.parents.collect {|p| p.id} + [technology_types(:new_parent)])}
    assert assigns(:technology_type)
    assert_equal 2,assigns(:technology_type).parents.size
    assert_equal assigns(:technology_type).parents.last, technology_types(:new_parent)
  end
  
  test "should delete assay" do
    login_as(:quentin)
    technology_type = TechnologyType.create(:title => "delete_me")
    assert_difference('TechnologyType.count', -1) do
      delete :destroy, :id => technology_type.id
    end
    assert_nil flash[:error]
    assert_redirected_to manage_technology_types_path
  end
  
  test "should not delete technology_type with child" do
    login_as(:quentin)
    assert_no_difference('TechnologyType.count') do
      delete :destroy, :id => technology_types(:technology_type_with_child).id
    end
    assert flash[:error]
    assert_redirected_to manage_technology_types_path
  end 
  
  test "should not delete technology_type with assays" do
    login_as(:quentin)
    assert_no_difference('TechnologyType.count') do
      delete :destroy, :id => technology_types(:child_technology_type_with_assay).id
    end
    assert flash[:error]
    assert_redirected_to manage_technology_types_path
  end
  
  test "should not delete technology_type with children with assays" do
    login_as(:quentin)
    assert_no_difference('TechnologyType.count') do
      delete :destroy, :id => technology_types(:technology_type_with_only_child_assays).id
    end
    assert flash[:error]
    assert_redirected_to manage_technology_types_path
  end

  test "should show technology types to public" do
    logout
    get :show, :id => technology_types(:technology_type_with_child)
    assert_response :success
    assert_not_nil assigns(:technology_type)
  end

  test 'should show only related authorized assays' do
    assays = technology_types(:child_technology_type_with_assay).assays
    authorized_assays = assays.select(&:can_view?)
    assert_equal 2, assays.count
    assert_equal 1, authorized_assays.count

    get :show, :id => technology_types(:child_technology_type_with_assay)
    assert_response :success
    assert_select 'a', :text => authorized_assays.first.title, :count => 1
    assert_select 'a', :text => (assays - authorized_assays).first.title, :count => 0
  end
end
