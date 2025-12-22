require 'test_helper'

class TechnologyTypesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  def setup
    login_as(:aaron)
  end

  test 'should show assay types to public' do
    assay = FactoryBot.create :experimental_assay, technology_type_uri: 'http://jermontology.org/ontology/JERMOntology#Imaging', policy: FactoryBot.create(:public_policy)
    logout
    get :show, params: { uri: assay.technology_type_uri }
    assert_response :success
    assert_select 'h1', text: /Technology type 'Imaging'/
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item div.list_item_title a[href=?]', assay_path(assay), text: /#{assay.title}/
    end
    assert_select 'div.ontology_nav a.parent_term', text: /technology type/i
  end

  test 'hierarchy' do
    assay = FactoryBot.create :experimental_assay, technology_type_uri: 'http://jermontology.org/ontology/JERMOntology#Microscopy', policy: FactoryBot.create(:public_policy)

    logout
    get :show, params: { uri: 'http://jermontology.org/ontology/JERMOntology#Technology_type' }
    assert_response :success
    assert_select 'h1', text: /Technology type 'Technology type'/
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item div.list_item_title a[href=?]', assay_path(assay), text: /#{assay.title}/
    end
    assert_select 'div.ontology_nav a.child_term', text: /imaging \(1\)/i
  end

  test 'default page' do
    assay = FactoryBot.create :experimental_assay, policy: FactoryBot.create(:public_policy)
    get :show
    assert_response :success
    assert_select 'h1', text: /Technology type 'Technology type'/
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item div.list_item_title a[href=?]', assay_path(assay), text: /#{assay.title}/
    end
  end

  test 'should show only related authorized assays' do
    pub_assay = FactoryBot.create :experimental_assay, technology_type_uri: 'http://jermontology.org/ontology/JERMOntology#Imaging', policy: FactoryBot.create(:public_policy)
    priv_assay = FactoryBot.create :experimental_assay, technology_type_uri: 'http://jermontology.org/ontology/JERMOntology#Imaging', policy: FactoryBot.create(:private_policy)
    logout
    get :show, params: { uri: 'http://jermontology.org/ontology/JERMOntology#Technology_type' }
    assert_response :success
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item div.list_item_title a[href=?]', assay_path(pub_assay), text: /#{pub_assay.title}/
      assert_select 'div.list_item div.list_item_title a[href=?]', assay_path(priv_assay), text: /#{priv_assay.title}/, count: 0
    end

    assert_select 'div.ontology_nav a.child_term', text: /imaging \(1\)/i
  end

  test 'unmatched label passed render term suggestion page with ontology label' do
    assay = FactoryBot.create :experimental_assay, policy: FactoryBot.create(:public_policy)
    # with unmatched label
    get :show, params: { uri: assay.technology_type_uri, label: 'frog' }
    # undefined label with uri in ontology will go to suggestion page pointing to term with ontology label
    assert_not_nil flash[:notice]
    assert_select 'h1', text: /Technology type 'frog'/
    assert_select 'div.list_items_container', count: 0
  end

  test 'correct label passed with ontology uri should render correctly' do
    # assay with ontology types
    assay = FactoryBot.create :experimental_assay, policy: FactoryBot.create(:public_policy)
    # with correct label
    get :show, params: { uri: assay.technology_type_uri, label: assay.technology_type_label }
    assert_select 'h1', text: /Technology type '#{assay.technology_type_label}'/
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item div.list_item_title a[href=?]', assay_path(assay), text: /#{assay.title}/
    end
  end
  test 'no label passed render the same page as long as the same ontolgoy uri is passed' do
    assay = FactoryBot.create :experimental_assay, policy: FactoryBot.create(:public_policy)
    # without label
    get :show, params: { uri: assay.technology_type_uri }
    assert_select 'h1', text: /Technology type '#{assay.technology_type_label}'/
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item div.list_item_title a[href=?]', assay_path(assay), text: /#{assay.title}/
    end
  end

  test 'correct label passed with suggested technology type uri should render correctly' do
    # assay with suggested types
    suggested_technology_type = FactoryBot.create(:suggested_technology_type, label: 'this is a techno type')
    assay = FactoryBot.create :experimental_assay, suggested_technology_type: suggested_technology_type, policy: FactoryBot.create(:public_policy)

    # with correct label
    get :show, params: { uri: suggested_technology_type.uri, label: 'this is a techno type' }
    assert_select 'h1', text: /Technology type 'this is a techno type'/
    assert_select 'div.list_items_container' do
      assert_select 'div.list_item div.list_item_title a[href=?]', assay_path(assay), text: /#{assay.title}/
    end
  end

  test 'unmatched label passed render term suggestion page with suggested_technology_type_label' do
    suggested_technology_type = FactoryBot.create(:suggested_technology_type)
    assay = FactoryBot.create :experimental_assay, suggested_technology_type: suggested_technology_type, policy: FactoryBot.create(:public_policy)
    get :show, params: { uri: assay.technology_type_uri, label: 'frog' }
    assert_not_nil flash[:notice]
    assert_select 'h1', text: /Technology type 'frog'/
    assert_select 'div.list_items_container', count: 0
  end
end
