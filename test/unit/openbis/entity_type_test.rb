require 'test_helper'
require 'openbis_test_helper'

class EntityTypeTest < ActiveSupport::TestCase
  # run test only if connected to real server as I did not not want to make so many mocked queries for
  # a client that needs to change.
  # other tests may have already mock the calls
  def self.mocked?
    Fairdom::OpenbisApi::ApplicationServerQuery.method_defined? :mocked?
    # so that it won't run on travis
    true
  end

  def setup
    @openbis_endpoint = OpenbisEndpoint.new project: FactoryBot.create(:project), username: 'seek', password: 'seek',
                                            web_endpoint: 'https://127.0.0.1:8443/openbis/openbis',
                                            as_endpoint: 'https://127.0.0.1:8443/openbis/openbis',
                                            dss_endpoint: 'https://127.0.0.1:8443/doesnotmatter',
                                            space_perm_id: 'SEEK',
                                            refresh_period_mins: 60

    @openbis_endpoint.clear_metadata_store
  end

  def test_warn_on_mocked_tests
    skip 'EntityType tests skipped as mocked query detected' if EntityTypeTest.mocked?
    assert true
  end

  # test 'check if mock present' do
  #  skip 'only to check if the mocked? implementation works'
  #  refute self.class.mocked?
  #  mock_openbis_calls
  #  assert self.class.mocked?
  # end

  test 'setup work' do
    return if EntityTypeTest.mocked?
    assert @openbis_endpoint.test_authentication
  end

  test 'SampleType by code' do
    return if EntityTypeTest.mocked?

    code = 'EXPERIMENTAL_STEP'
    type = Seek::Openbis::EntityType.SampleType(@openbis_endpoint, code, true)
    assert type
    assert_equal code, type.code
    assert_equal 'Sample', type.entity_type
    assert_equal 'SampleType', type.type_name
  end

  test 'SampleType all' do
    return if EntityTypeTest.mocked?

    types = Seek::Openbis::EntityType.SampleType(@openbis_endpoint).all(true)
    assert types
    assert_equal 25, types.size

    codes = types.map(&:code)
    assert_includes codes, 'BACTERIA'
  end

  test 'SampleType by semantic annotation' do
    return if EntityTypeTest.mocked?
    skip 'Semantic annotations are not currently available in OBIS production releases'
    semantic = Seek::Openbis::SemanticAnnotation.new

    semantic.predicateAccessionId = 'po_acc_t'
    semantic.descriptorAccessionId = 'do_acc_t'
    types = Seek::Openbis::EntityType.SampleType(@openbis_endpoint).find_by_semantic(semantic)

    assert types
    assert_equal 2, types.size

    codes = types.map(&:code)
    assert_includes codes, 'TZ_ASSAY'
    assert_equal %w[CHEMICAL TZ_ASSAY], codes

    puts '-----------------'
    semantic.predicateAccessionId = 'is_a'
    semantic.descriptorAccessionId = 'assay'
    types = Seek::Openbis::EntityType.SampleType(@openbis_endpoint).find_by_semantic(semantic)

    assert types
    assert_equal 2, types.size

    semantic.predicateAccessionId = 'is_a'
    semantic.descriptorAccessionId = 'assay_missing_there'
    types = Seek::Openbis::EntityType.SampleType(@openbis_endpoint).find_by_semantic(semantic)

    assert types
    assert_equal 0, types.size
  end

  test 'Samples can be found by types codes' do
    return if EntityTypeTest.mocked?

    codes = ['EXPERIMENTAL_STEP']

    zamples = Seek::Openbis::Zample.new(@openbis_endpoint).find_by_type_codes(codes)
    assert zamples
    assert_equal 8, zamples.size

    codes = %w[EXPERIMENTAL_STEP STORAGE]
    zamples = Seek::Openbis::Zample.new(@openbis_endpoint).find_by_type_codes(codes)
    assert zamples
    assert_equal 10, zamples.size

    codes = ['TZ_MISSING_TYPE']
    zamples = Seek::Openbis::Zample.new(@openbis_endpoint).find_by_type_codes(codes)
    assert zamples
    assert_equal 0, zamples.size
  end

  test 'All samples can be found' do
    return if EntityTypeTest.mocked?

    zamples = Seek::Openbis::Zample.new(@openbis_endpoint).all
    assert zamples
    assert_equal 16, zamples.size
  end

  test 'DataSetType by code' do
    return if EntityTypeTest.mocked?

    code = 'RAW_DATA'
    type = Seek::Openbis::EntityType.DataSetType(@openbis_endpoint, code, true)
    assert type
    assert_equal code, type.code
    assert_equal 'DataSet', type.entity_type
    assert_equal 'DataSetType', type.type_name
  end

  test 'DatasetType all' do
    return if EntityTypeTest.mocked?

    types = Seek::Openbis::EntityType.DataSetType(@openbis_endpoint).all(true)
    assert types
    assert_equal 6, types.size

    codes = types.map(&:code)
    assert_includes codes, 'RAW_DATA'
  end

  test 'DataSets can be found by types codes' do
    return if EntityTypeTest.mocked?

    codes = ['RAW_DATA']

    sets = Seek::Openbis::Dataset.new(@openbis_endpoint).find_by_type_codes(codes)
    assert sets
    assert_equal 4, sets.size

    codes = %w[RAW_DATA ANALYZED_DATA]
    sets = Seek::Openbis::Dataset.new(@openbis_endpoint).find_by_type_codes(codes)
    assert sets
    assert_equal 6, sets.size

    codes = ['TZ_MISSING_TYPE']
    sets = Seek::Openbis::Dataset.new(@openbis_endpoint).find_by_type_codes(codes)
    assert sets
    assert_equal 0, sets.size
  end

  test 'ExperimentType by code' do
    return if EntityTypeTest.mocked?

    code = 'DEFAULT_EXPERIMENT'
    type = Seek::Openbis::EntityType.ExperimentType(@openbis_endpoint, code, true)
    assert type
    assert_equal code, type.code
    assert_equal 'Experiment', type.entity_type
    assert_equal 'ExperimentType', type.type_name
  end

  test 'ExperimentType all' do
    return if EntityTypeTest.mocked?

    types = Seek::Openbis::EntityType.ExperimentType(@openbis_endpoint).all(true)
    assert types
    assert_equal 6, types.size

    codes = types.map(&:code)
    assert_includes codes, 'DEFAULT_EXPERIMENT'
  end

  test 'ExperimentType by codes' do
    return if EntityTypeTest.mocked?

    codes = %w[DEFAULT_EXPERIMENT MATERIALS]
    types = Seek::Openbis::EntityType.ExperimentType(@openbis_endpoint).find_by_codes(codes, true)
    assert types
    assert_equal 2, types.size

    codes = types.map(&:code)
    assert_includes codes, 'DEFAULT_EXPERIMENT'
  end

  test 'Experiment can be found by types codes' do
    return if EntityTypeTest.mocked?

    codes = ['DEFAULT_EXPERIMENT']

    sets = Seek::Openbis::Experiment.new(@openbis_endpoint).find_by_type_codes(codes)
    assert sets
    assert_equal 3, sets.size

    codes = %w[DEFAULT_EXPERIMENT MATERIALS]
    sets = Seek::Openbis::Experiment.new(@openbis_endpoint).find_by_type_codes(codes)
    assert sets
    assert_equal 15, sets.size

    codes = ['TZ_MISSING_TYPE']
    sets = Seek::Openbis::Experiment.new(@openbis_endpoint).find_by_type_codes(codes)
    assert sets
    assert_equal 0, sets.size
  end
end
