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


  test "unmatched label passed redirect to term suggestion page with ontology label or suggested_assay_type_label" do
    assay = Factory :experimental_assay,:policy=>Factory(:public_policy)

    get :show, :uri=>assay.technology_type_uri,:label=>"frog"
    # undefined label with uri in ontology will go to suggestion page pointing to term with ontology label
    assert_not_nil flash[:error]
    assert_select "h1",:text=>/Technology type &#x27;frog&#x27;/


    suggested_technology_type = Factory(:suggested_technology_type)
    assay = Factory :experimental_assay,:technology_type_uri => suggested_technology_type.uri,:policy=>Factory(:public_policy)
    get :show, :uri=> assay.technology_type_uri,:label=>"frog"

    assert_not_nil flash[:error]
    assert_select "h1",:text=>/Technology type &#x27;frog&#x27;/
  end

end
