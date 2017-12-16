require 'test_helper'
require 'openbis_test_helper'


class EntityTypeTest < ActiveSupport::TestCase

  def setup

    @openbis_endpoint = OpenbisEndpoint.new project: Factory(:project), username: 'seek', password: 'seek',
                                    web_endpoint: 'https://127.0.0.1:8443/openbis/openbis',
                                    as_endpoint: 'https://127.0.0.1:8443/openbis/openbis',
                                    dss_endpoint: 'https://127.0.0.1:8443/doesnotmatter',
                                    space_perm_id: 'SEEK',
                                    refresh_period_mins: 60

    @openbis_endpoint.clear_metadata_store

  end

  test 'setup work' do
    assert @openbis_endpoint.test_authentication
  end

  test 'SampleType by code' do
    code = 'TZ_ASSAY'
    type = Seek::Openbis::EntityType.SampleType(@openbis_endpoint, code, true)
    assert type
    assert_equal code, type.code
    assert_equal 'Sample', type.entity_type
    assert_equal 'SampleType', type.type_name

  end

  test 'SampleType all' do
    types = Seek::Openbis::EntityType.SampleType(@openbis_endpoint).all(true)
    assert types
    assert_equal 25, types.size

    codes = types.map { |t| t.code}
    assert_includes codes, 'TZ_ASSAY'
  end

  test 'SampleType by semantic annotation' do
    semantic = Seek::Openbis::SemanticAnnotation.new

    semantic.predicateAccessionId = 'po_acc_t'
    semantic.descriptorAccessionId = 'do_acc_t'
    types = Seek::Openbis::EntityType.SampleType(@openbis_endpoint).find_by_semantic(semantic)

    assert types
    assert_equal 2, types.size

    codes = types.map { |t| t.code}
    assert_includes codes, 'TZ_ASSAY'
    assert_equal ['CHEMICAL','TZ_ASSAY'], codes

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
    codes = ['TZ_ASSAY']

    zamples = Seek::Openbis::Zample.new(@openbis_endpoint).find_by_type_codes(codes)
    assert zamples
    assert_equal 2, zamples.size

    codes = ['TZ_ASSAY','STORAGE']
    zamples = Seek::Openbis::Zample.new(@openbis_endpoint).find_by_type_codes(codes)
    assert zamples
    assert_equal 4, zamples.size

    codes = ['TZ_MISSING_TYPE']
    zamples = Seek::Openbis::Zample.new(@openbis_endpoint).find_by_type_codes(codes)
    assert zamples
    assert_equal 0, zamples.size
  end

  test 'All samples can be found' do

    zamples = Seek::Openbis::Zample.new(@openbis_endpoint).all
    assert zamples
    assert_equal 8, zamples.size

  end

  test 'DataSetType by code' do
    code = 'TZ_FAIR'
    type = Seek::Openbis::EntityType.DataSetType(@openbis_endpoint, code, true)
    assert type
    assert_equal code, type.code
    assert_equal 'DataSet', type.entity_type
    assert_equal 'DataSetType', type.type_name

  end

  test 'DatasetType all' do
    types = Seek::Openbis::EntityType.DataSetType(@openbis_endpoint).all(true)
    assert types
    assert_equal 7, types.size

    codes = types.map { |t| t.code}
    assert_includes codes, 'TZ_FAIR'
  end

  test 'DataSets can be found by types codes' do
    codes = ['TZ_FAIR']

    sets = Seek::Openbis::Dataset.new(@openbis_endpoint).find_by_type_codes(codes)
    assert sets
    assert_equal 7, sets.size

    codes = ['TZ_FAIR','UNKNOWN']
    sets = Seek::Openbis::Dataset.new(@openbis_endpoint).find_by_type_codes(codes)
    assert sets
    assert_equal 8, sets.size

    codes = ['TZ_MISSING_TYPE']
    sets = Seek::Openbis::Dataset.new(@openbis_endpoint).find_by_type_codes(codes)
    assert sets
    assert_equal 0, sets.size
  end

end