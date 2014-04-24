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
