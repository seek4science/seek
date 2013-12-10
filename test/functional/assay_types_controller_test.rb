require 'test_helper'

class AssayTypesControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include RestTestCases
  
  def setup
    login_as(:aaron)
  end

  def rest_api_test_object
    @object=assay_types(:metabolomics)
  end

  test "show" do
    login_as(:quentin)
    get :show,:id=>assay_types(:metabolomics)
    assert_response :success
  end

  test "should show manage page" do
    login_as(:quentin)
    get :manage
    assert_response :success
    assert_not_nil assigns(:assay_types)
  end
  
  test "should also show manage page for non-admin" do
    login_as(:cant_edit)
    get :manage
    assert_response :success
    assert_not_nil assigns(:assay_types)
  end

  test "should show manage page for pal" do
    login_as Factory(:pal).user
    get :manage
    assert_response :success
    assert_not_nil assigns(:assay_types)
  end
  
  test "should show new" do
    login_as(:quentin)
    get :new
    assert_response :success
    assert_not_nil assigns(:assay_type)
  end
  
  test "should show edit" do
    login_as(:quentin)
    get :edit, :id=>assay_types(:assay_type_with_child).id
    assert_response :success
    assert_not_nil assigns(:assay_type)
  end
  
  test "should create" do
    login_as(:quentin)
    assert_difference("AssayType.count") do
      post :create,:assay_type=>{:title => "test_assay_type", :parent_id => [assay_types(:assay_type_with_child_and_assay).id]}      
    end
    assay_type = assigns(:assay_type)
    assert assay_type.valid?
    assert_equal 1,assay_type.parents.size
    assert_redirected_to manage_assay_types_path
  end
  
  test "should update title" do
    login_as(:quentin)
    assay_type = assay_types(:child_assay_type)
    put :update, :id => assay_type.id, :assay_type => {:title => "child_assay_type_a", :parent_id => assay_type.parents.collect {|p| p.id}}
    assert assigns(:assay_type)
    assert_equal "child_assay_type_a", assigns(:assay_type).title
  end
  
  test "should update parents" do
    login_as(:quentin)
    assay_type = assay_types(:child_assay_type)
    assert_equal 1,assay_type.parents.size
    put :update,:id=>assay_type.id,:assay_type=>{:title => assay_type.title, :parent_id => (assay_type.parents.collect {|p| p.id} + [assay_types(:new_parent)])}
    assert assigns(:assay_type)
    assert_equal 2,assigns(:assay_type).parents.size
    assert_equal assigns(:assay_type).parents.last, assay_types(:new_parent)
  end
  
  test "should delete assay" do
    login_as(:quentin)
    assay_type = AssayType.create(:title => "delete_me")
    assert_difference('AssayType.count', -1) do
      delete :destroy, :id => assay_type.id
    end
    assert_nil flash[:error]
    assert_redirected_to manage_assay_types_path
  end
  
  test "should not delete assay_type with child" do
    login_as(:quentin)
    assert_no_difference('AssayType.count') do
      delete :destroy, :id => assay_types(:assay_type_with_child).id
    end
    assert flash[:error]
    assert_redirected_to manage_assay_types_path
  end 
  
  test "should not delete assay_type with assays" do
    login_as(:quentin)
    assert_no_difference('AssayType.count') do
      delete :destroy, :id => assay_types(:child_assay_type_with_assay).id
    end
    assert flash[:error]
    assert_redirected_to manage_assay_types_path
  end
  
  test "should not delete assay_type with children with assays" do
    login_as(:quentin)
    assert_no_difference('AssayType.count') do
      delete :destroy, :id => assay_types(:assay_type_with_only_child_assays).id
    end
    assert flash[:error]
    assert_redirected_to manage_assay_types_path
  end

  test "should show assay types to public" do
    logout
    get :show, :id => assay_types(:metabolomics)
    assert_response :success
    assert_not_nil assigns(:assay_type)
  end

  test 'should show only related authorized assays' do
    assays = assay_types(:child_assay_type_with_assay).assays
    authorized_assays = assays.select(&:can_view?)
    assert_equal 2, assays.count
    assert_equal 1, authorized_assays.count

    get :show, :id => assay_types(:child_assay_type_with_assay)
    assert_response :success
    assert_select 'a', :text => authorized_assays.first.title, :count => 1
    assert_select 'a', :text => (assays - authorized_assays).first.title, :count => 0
  end
end
