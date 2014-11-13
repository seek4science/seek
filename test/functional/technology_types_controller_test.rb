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


  test "unmatched label passed render term suggestion page with ontology label" do
    assay = Factory :experimental_assay, :policy => Factory(:public_policy)
    #with unmatched label
    get :show, :uri => assay.technology_type_uri, :label => "frog"
    # undefined label with uri in ontology will go to suggestion page pointing to term with ontology label
    assert_not_nil flash[:notice]
    assert_select "h1", :text => /Technology type &#x27;frog&#x27;/
    assert_select "div.list_items_container", :count => 0
  end

  test "correct label passed with ontology uri should render correctly" do
    # assay with ontology types
    assay = Factory :experimental_assay, :policy => Factory(:public_policy)
    #with correct label
    get :show, :uri => assay.technology_type_uri, :label => assay.technology_type_label
    assert_select "h1", :text => /Technology type &#x27;#{assay.technology_type_label}&#x27;/
    assert_select "div.list_items_container" do
      assert_select "div.list_item div.list_item_content div.list_item_title a[href=?]", assay_path(assay), :text => /#{assay.title}/
    end
  end
  test "no label passed render the same page as long as the same ontolgoy uri is passed" do
    assay = Factory :experimental_assay, :policy => Factory(:public_policy)
    #without label
    get :show, :uri => assay.technology_type_uri
    assert_select "h1", :text => /Technology type &#x27;#{assay.technology_type_label}&#x27;/
    assert_select "div.list_items_container" do
      assert_select "div.list_item div.list_item_content div.list_item_title a[href=?]", assay_path(assay), :text => /#{assay.title}/
    end
  end


  test "correct label passed with suggested technology type uri should render correctly" do
    #assay with suggested types
    suggested_technology_type = Factory(:suggested_technology_type, :label=>"this is a techno type")
    assay = Factory :experimental_assay, :suggested_technology_type => suggested_technology_type, :policy => Factory(:public_policy)

    #with correct label
    get :show, :uri => suggested_technology_type.uri, :label => "this is a techno type"
    assert_select "h1", :text => /Technology type &#x27;this is a techno type&#x27;/
    assert_select "div.list_items_container" do
      assert_select "div.list_item div.list_item_content div.list_item_title a[href=?]", assay_path(assay), :text => /#{assay.title}/
    end
  end


  test "unmatched label passed render term suggestion page with suggested_technology_type_label" do
    suggested_technology_type = Factory(:suggested_technology_type)
    assay = Factory :experimental_assay, :suggested_technology_type => suggested_technology_type,:policy => Factory(:public_policy)
    get :show, :uri => assay.technology_type_uri, :label => "frog"
    assert_not_nil flash[:notice]
    assert_select "h1", :text => /Technology type &#x27;frog&#x27;/
    assert_select "div.list_items_container", :count => 0
  end



end
