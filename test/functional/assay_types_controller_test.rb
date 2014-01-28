require 'test_helper'

class AssayTypesControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  
  def setup
    login_as(:aaron)
  end


  test "should show assay types to public" do
    assay = Factory :experimental_assay,:assay_type_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics",:policy=>Factory(:public_policy)
    logout
    get :show, :uri=>assay.assay_type_uri
    assert_response :success
    assert_select "h1",:text=>/Assay type &#x27;Fluxomics&#x27;/
    assert_select "div.list_items_container" do
      assert_select "div.list_item div.list_item_content div.list_item_title a[href=?]",assay_path(assay),:text=>/#{assay.title}/
    end
    assert_select "div.ontology_nav a.parent_term",:text=>/experimental assay type/i
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
 test "hierarchy" do
    assay = Factory :experimental_assay,:assay_type_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Flux_balance_analysis",:policy=>Factory(:public_policy)
  logout
    get :show, :uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Experimental_assay_type"
    assert_response :success
    assert_select "h1",:text=>/Assay type &#x27;Experimental assay type&#x27;/
    assert_select "div.list_items_container" do
      assert_select "div.list_item div.list_item_content div.list_item_title a[href=?]",assay_path(assay),:text=>/#{assay.title}/
    end
    assert_select "div.ontology_nav a.child_term",:text=>/fluxomics \(1\)/i
  end
 test "should show assay types to public" do
    logout
    get :show, :id => assay_types(:metabolomics)
    assert_response :success
    assert_not_nil assigns(:assay_type)
  end



  test "default page" do
    assay = Factory :experimental_assay,:policy=>Factory(:public_policy)
    get :show
    assert_response :success
    assert_select "h1",:text=>/Assay type &#x27;Experimental assay type&#x27;/
    assert_select "div.list_items_container" do
      assert_select "div.list_item div.list_item_content div.list_item_title a[href=?]",assay_path(assay),:text=>/#{assay.title}/
    end
  end

  test 'should show only related authorized assays' do
    pub_assay = Factory :experimental_assay,:assay_type_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics",:policy=>Factory(:public_policy)
    priv_assay = Factory :experimental_assay,:assay_type_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics",:policy=>Factory(:private_policy)
    logout
    get :show, :uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Experimental_assay_type"
    assert_response :success
    assert_select "div.list_items_container" do
      assert_select "div.list_item div.list_item_content div.list_item_title a[href=?]",assay_path(pub_assay),:text=>/#{pub_assay.title}/
      assert_select "div.list_item div.list_item_content div.list_item_title a[href=?]",assay_path(priv_assay),:text=>/#{priv_assay.title}/,:count=>0
    end

    assert_select "div.ontology_nav a.child_term",:text=>/fluxomics \(1\)/i
  end

  test "modelling analysis" do
    assay = Factory :modelling_assay
    get :show,:uri=> assay.assay_type_uri
    assert_response :success
    assert_select "h1",:text=>/Biological problem addressed &#x27;Model analysis type&#x27;/
  end

  test "label passed overrides" do
    assay = Factory :experimental_assay,:policy=>Factory(:public_policy)

    get :show, :uri=>assay.assay_type_uri,:label=>"frog"
    assert_response :success
    assert_select "h1",:text=>/Assay type &#x27;frog&#x27;/
    assert_select "div.list_items_container" do
      assert_select "div.list_item div.list_item_content div.list_item_title a[href=?]",assay_path(assay),:text=>/#{assay.title}/
    end
  end
end
