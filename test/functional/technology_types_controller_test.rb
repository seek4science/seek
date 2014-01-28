require 'test_helper'

class TechnologyTypesControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:aaron)
  end


  test "should show assay types to public" do
    assay = Factory :experimental_assay,:technology_type_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Imaging",:policy=>Factory(:public_policy)
    logout
    get :show, :uri=>assay.technology_type_uri
    assert_response :success
    assert_select "h1",:text=>/Technology type &#x27;Imaging&#x27;/
    assert_select "div.list_items_container" do
      assert_select "div.list_item div.list_item_content div.list_item_title a[href=?]",assay_path(assay),:text=>/#{assay.title}/
    end
    assert_select "div.ontology_nav a.parent_term",:text=>/technology type/i
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

 test "hierarchy" do
    assay = Factory :experimental_assay,:technology_type_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Microscopy",:policy=>Factory(:public_policy)

    logout
    get :show, :uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Technology_type"
    assert_response :success
    assert_select "h1",:text=>/Technology type &#x27;Technology type&#x27;/
    assert_select "div.list_items_container" do
      assert_select "div.list_item div.list_item_content div.list_item_title a[href=?]",assay_path(assay),:text=>/#{assay.title}/
    end
    assert_select "div.ontology_nav a.child_term",:text=>/imaging \(1\)/i
  end

  test "default page" do
    assay = Factory :experimental_assay,:policy=>Factory(:public_policy)
    get :show
    assert_response :success
    assert_select "h1",:text=>/Technology type &#x27;Technology type&#x27;/
    assert_select "div.list_items_container" do
      assert_select "div.list_item div.list_item_content div.list_item_title a[href=?]",assay_path(assay),:text=>/#{assay.title}/
    end
  end

  test 'should show only related authorized assays' do
    pub_assay = Factory :experimental_assay,:technology_type_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Imaging",:policy=>Factory(:public_policy)
    priv_assay = Factory :experimental_assay,:technology_type_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Imaging",:policy=>Factory(:private_policy)
    logout
    get :show, :uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Technology_type"
    assert_response :success
    assert_select "div.list_items_container" do
      assert_select "div.list_item div.list_item_content div.list_item_title a[href=?]",assay_path(pub_assay),:text=>/#{pub_assay.title}/
      assert_select "div.list_item div.list_item_content div.list_item_title a[href=?]",assay_path(priv_assay),:text=>/#{priv_assay.title}/,:count=>0
    end

    assert_select "div.ontology_nav a.child_term",:text=>/imaging \(1\)/i
  end


  test "label passed overrides" do
    assay = Factory :experimental_assay,:policy=>Factory(:public_policy)

    get :show, :uri=>assay.technology_type_uri,:label=>"frog"
    assert_response :success
    assert_select "h1",:text=>/Technology type &#x27;frog&#x27;/
    assert_select "div.list_items_container" do
      assert_select "div.list_item div.list_item_content div.list_item_title a[href=?]",assay_path(assay),:text=>/#{assay.title}/
    end
  end

end
