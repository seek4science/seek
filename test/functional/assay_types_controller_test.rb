require 'test_helper'

class AssayTypesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  def setup
    login_as(FactoryBot.create(:admin))
  end

  test 'should show assay types to public' do
    assay = FactoryBot.create :experimental_assay, assay_type_uri: 'http://jermontology.org/ontology/JERMOntology#Fluxomics', policy: FactoryBot.create(:public_policy)
    logout
    get :show, params: { uri: assay.assay_type_uri }
    assert_response :success
    assert_select 'h1', text: /Assay type 'Fluxomics'/
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item div.list_item_title a[href=?]', assay_path(assay), text: /#{assay.title}/
    end
    assert_select 'div.ontology_nav a.parent_term', text: /experimental assay type/i
  end

  test 'hierarchy' do
    assay = FactoryBot.create :experimental_assay, title: 'flux balance assay', assay_type_uri: 'http://jermontology.org/ontology/JERMOntology#Flux_balance_analysis', policy: FactoryBot.create(:public_policy)
    logout
    get :show, params: { uri: 'http://jermontology.org/ontology/JERMOntology#Experimental_assay_type' }
    assert_response :success

    assert_select 'h1', text: /Assay type 'Experimental assay type'/
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item div.list_item_title a[href=?]', assay_path(assay)
    end
    assert_select 'div.ontology_nav a.child_term', text: /fluxomics \(1\)/i
  end

  test 'default page' do
    assay = FactoryBot.create :experimental_assay, policy: FactoryBot.create(:public_policy)
    get :show
    assert_response :success
    assert_select 'h1', text: /Assay type 'Experimental assay type'/
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item div.list_item_title a[href=?]', assay_path(assay), text: /#{assay.title}/
    end
  end

  test 'should show only related authorized assays' do
    pub_assay = FactoryBot.create :experimental_assay, assay_type_uri: 'http://jermontology.org/ontology/JERMOntology#Fluxomics', policy: FactoryBot.create(:public_policy)
    priv_assay = FactoryBot.create :experimental_assay, assay_type_uri: 'http://jermontology.org/ontology/JERMOntology#Fluxomics', policy: FactoryBot.create(:private_policy)
    logout
    get :show, params: { uri: 'http://jermontology.org/ontology/JERMOntology#Experimental_assay_type' }
    assert_response :success
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item div.list_item_title a[href=?]', assay_path(pub_assay), text: /#{pub_assay.title}/
      assert_select 'div.list_item div.list_item_title a[href=?]', assay_path(priv_assay), text: /#{priv_assay.title}/, count: 0
    end

    assert_select 'div.ontology_nav a.child_term', text: /fluxomics \(1\)/i
  end

  test 'modelling analysis' do
    assay = FactoryBot.create :modelling_assay
    get :show, params: { uri: assay.assay_type_uri }
    assert_response :success
    assert_select 'h1', text: /Biological problem addressed 'Model analysis type'/
  end

  test 'unmatched label passed render term suggestion page with ontology label' do
    assay = FactoryBot.create :experimental_assay, policy: FactoryBot.create(:public_policy)
    # with unmatched label
    get :show, params: { uri: assay.assay_type_uri, label: 'frog' }
    # undefined label with uri in ontology will go to suggestion page pointing to term with ontology label
    assert_not_nil flash[:notice]
    assert_select 'h1', text: /Assay type 'frog'/
    assert_select 'div.list_items_container', count: 0
  end

  test 'correct label passed with ontology uri should render correctly' do
    assay = FactoryBot.create :experimental_assay, policy: FactoryBot.create(:public_policy)
    # assay with ontology types
    assay = FactoryBot.create :experimental_assay, policy: FactoryBot.create(:public_policy)
    # with correct label
    get :show, params: { uri: assay.assay_type_uri, label: assay.assay_type_label }
    assert_select 'h1', text: /Assay type '#{assay.assay_type_label}'/
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item div.list_item_title a[href=?]', assay_path(assay), text: /#{assay.title}/
    end
  end

  test 'no label passed render the same page as long as the same ontolgoy uri is passed' do
    assay = FactoryBot.create :experimental_assay, policy: FactoryBot.create(:public_policy)
    # without label
    get :show, params: { uri: assay.assay_type_uri }
    assert_select 'h1', text: /Assay type '#{assay.assay_type_label}'/i
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item div.list_item_title a[href=?]', assay_path(assay), text: /#{assay.title}/
    end
  end

  test 'correct label passed with suggested assay type should render correctly' do
    # assay with suggested types
    suggested_assay_type = FactoryBot.create(:suggested_assay_type, label: 'this is an assay type')
    assay = FactoryBot.create :experimental_assay, suggested_assay_type: suggested_assay_type, policy: FactoryBot.create(:public_policy)

    # with correct label
    get :show, params: { uri: suggested_assay_type.uri, label: 'this is an assay type' }
    assert_select 'h1', text: /Assay type 'this is an assay type'/
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item div.list_item_title a[href=?]', assay_path(assay), text: /#{assay.title}/
    end
  end

  test 'unmatched label passed render term suggestion page with suggested_assay_type_label' do
    suggested_assay_type = FactoryBot.create(:suggested_assay_type)
    assay = FactoryBot.create :experimental_assay, suggested_assay_type: suggested_assay_type, policy: FactoryBot.create(:public_policy)
    get :show, params: { uri: assay.assay_type_uri, label: 'frog' }
    assert_not_nil flash[:notice]
    assert_select 'h1', text: /Assay type 'frog'/
    assert_select 'div.list_items_container', count: 0
  end
end
