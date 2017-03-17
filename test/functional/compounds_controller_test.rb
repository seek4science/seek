require 'test_helper'

class CompoundsControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include RdfTestCases

  def setup
    login_as(:quentin)
  end

  def rest_api_test_object
    @object = Factory(:compound)
  end

  test 'can only go to the compound admin when the user is admin' do
    login_as(:quentin)
    get :index
    assert_response :success
  end

  test 'can not go to the compound admin when the user is not admin' do
    login_as(:aaron)
    get :index
    assert_response :redirect
    assert_not_nil flash[:error]
  end

  test 'should create compound with synonyms and ids' do
    compound = { title: 'ATP', synonyms: "Adenosine triphosphate;Adenosine 5'-triphosphate", sabiork_id: '34',
                 chebi_ids: '30616;15422', kegg_ids: 'C00002' }
    post :create, compound: compound
    created_compound = assigns(:compound)

    assert_equal 'ATP', created_compound.title
    synonyms = created_compound.synonyms
    assert_equal 2, synonyms.count
    synonyms.each do |s|
      assert ['Adenosine triphosphate', "Adenosine 5'-triphosphate"].include?(s.title)
    end
    mappings = created_compound.mappings
    assert_equal 34, mappings.first.sabiork_id
    assert_equal 2, mappings.count
    mappings.each do |m|
      assert_equal 'C00002', m.kegg_id
      assert %w(30616 15422).include?(m.chebi_id)
    end
  end

  test 'should not create compound which already exist' do
    compound = compounds(:compound_glucose)
    post :create, compound: { title: compound.title }
    created_compound = assigns(:compound)
    assert_nil created_compound
  end

  test 'should not create compound with no name' do
    compound = { synonyms: "Adenosine triphosphate;Adenosine 5'-triphosphate", sabiork_id: '34',
                 chebi_ids: '30616;15422', kegg_ids: 'C00002' }
    post :create, compound: compound
    created_compound = assigns(:compound)
    assert_nil created_compound
  end

  test 'should update compound' do
    compound = Factory(:compound)
    Factory(:synonym, name: 'Glucose', substance: compound)
    mapping = Factory(:mapping)
    Factory(:mapping_link, substance: compound, mapping: mapping)

    put :update, :id => compound.id, "#{compound.id}_title" => compound.title, "#{compound.id}_synonyms" => 'glk', "#{compound.id}_sabiork_id" => '1406', "#{compound.id}_chebi_ids" => '17234', "#{compound.id}_kegg_ids" => 'C00293;C00031'
    updated_compound = assigns(:compound)

    synonyms = updated_compound.synonyms.collect(&:title)
    assert synonyms.include?('glk')
    mappings = updated_compound.mappings
    assert_equal 1406, mappings.first.sabiork_id
    assert_equal '17234', mappings.first.chebi_id
    assert_equal 2, mappings.count
    mappings.each do |m|
      assert %w(C00293 C00031).include?(m.kegg_id)
    end
  end

  test 'should not update compound with no name' do
    compound = Factory(:compound)
    assert_equal [], compound.synonyms
    assert_equal [], compound.mappings
    put :update, :id => compound.id, "#{compound.id}_synonyms" => 'glk', "#{compound.id}_sabiork_id" => '1406', "#{compound.id}_chebi_ids" => '17234', "#{compound.id}_kegg_ids" => 'C00293;C00031'

    updated_compound = assigns(:compound)
    assert_equal [], updated_compound.synonyms
    assert_equal [], updated_compound.mappings
  end

  test 'should delete compound, its synonyms, linked FSes and ECs' do
    # create compounds, synonyms, mappings, mapping_link, studied_factor, studied_factor_link, experimental_condition, experimental_condition_link
    compound = Factory(:compound)
    synonym = Factory(:synonym, name: 'Glucose', substance: compound)
    mapping = Factory(:mapping)
    mapping_link = Factory(:mapping_link, substance: compound, mapping: mapping)
    studied_factor = Factory(:studied_factor)
    studied_factor_link = Factory(:studied_factor_link, substance: compound, studied_factor: studied_factor)
    experimental_condition = Factory(:experimental_condition)
    experimental_condition_link = Factory(:experimental_condition_link, substance: synonym, experimental_condition: experimental_condition)
    assert_not_nil Compound.find_by_id compound.id
    assert_not_nil Synonym.find_by_id synonym.id
    assert_not_nil Mapping.find_by_id mapping.id
    assert_not_nil StudiedFactor.find_by_id studied_factor.id
    assert_not_nil ExperimentalCondition.find_by_id experimental_condition.id
    assert_not_nil MappingLink.find_by_id mapping_link.id
    assert_not_nil StudiedFactorLink.find_by_id studied_factor_link.id
    assert_not_nil ExperimentalConditionLink.find_by_id experimental_condition_link.id

    delete :destroy, id: compound.id

    assert_nil Synonym.find_by_id synonym.id
    assert_nil StudiedFactor.find_by_id studied_factor.id
    assert_nil ExperimentalCondition.find_by_id experimental_condition.id
    assert_nil MappingLink.find_by_id mapping_link.id
    assert_nil StudiedFactorLink.find_by_id studied_factor_link.id
    assert_nil ExperimentalConditionLink.find_by_id experimental_condition_link.id
  end
end
