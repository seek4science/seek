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
    assay = Factory :experimental_assay,:title=>"flux balance assay",:assay_type_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Flux_balance_analysis",:policy=>Factory(:public_policy)
  logout
    get :show, :uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Experimental_assay_type"
    assert_response :success

    assert_select "h1",:text=>/Assay type &#x27;Experimental assay type&#x27;/
    assert_select "div.list_items_container" do
      assert_select "div.list_item div.list_item_content div.list_item_title a[href=?]",assay_path(assay)
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

  test "unmatched label passed render term suggestion page with ontology label" do
    assay = Factory :experimental_assay, :policy => Factory(:public_policy)
    #with unmatched label
    get :show, :uri => assay.assay_type_uri, :label => "frog"
    # undefined label with uri in ontology will go to suggestion page pointing to term with ontology label
    assert_not_nil flash[:notice]
    assert_select "h1", :text => /Assay type &#x27;frog&#x27;/
    assert_select "div.list_items_container", :count => 0
  end

  test "correct label passed with ontology uri should render correctly" do
     assay = Factory :experimental_assay, :policy => Factory(:public_policy)
    # assay with ontology types
    assay = Factory :experimental_assay, :policy => Factory(:public_policy)
    #with correct label
    get :show, :uri => assay.assay_type_uri, :label => assay.assay_type_label
    assert_select "h1", :text => /Assay type &#x27;#{assay.assay_type_label}&#x27;/
    assert_select "div.list_items_container" do
      assert_select "div.list_item div.list_item_content div.list_item_title a[href=?]", assay_path(assay), :text => /#{assay.title}/
    end
  end

  test "no label passed render the same page as long as the same ontolgoy uri is passed" do
    assay = Factory :experimental_assay, :policy => Factory(:public_policy)
    #without label
    get :show, :uri => assay.assay_type_uri
    assert_select "h1", :text => /Assay type &#x27;#{assay.assay_type_label}&#x27;/i
    assert_select "div.list_items_container" do
      assert_select "div.list_item div.list_item_content div.list_item_title a[href=?]", assay_path(assay), :text => /#{assay.title}/
    end
  end


  test "correct label passed with suggested assay type should render correctly" do
    #assay with suggested types
    suggested_assay_type = Factory(:suggested_assay_type,:label=>"this is an assay type")
    assay = Factory :experimental_assay, :suggested_assay_type => suggested_assay_type, :policy => Factory(:public_policy)

    #with correct label
    get :show, :uri => suggested_assay_type.uri, :label => "this is an assay type"
    assert_select "h1", :text => /Assay type &#x27;this is an assay type&#x27;/
    assert_select "div.list_items_container" do
      assert_select "div.list_item div.list_item_content div.list_item_title a[href=?]", assay_path(assay), :text => /#{assay.title}/
    end
  end


  test "unmatched label passed render term suggestion page with suggested_assay_type_label" do
    suggested_assay_type = Factory(:suggested_assay_type)
    assay = Factory :experimental_assay, :suggested_assay_type => suggested_assay_type, :policy => Factory(:public_policy)
    get :show, :uri => assay.assay_type_uri, :label => "frog"
    assert_not_nil flash[:notice]
    assert_select "h1", :text => /Assay type &#x27;frog&#x27;/
    assert_select "div.list_items_container", :count => 0
  end

end
