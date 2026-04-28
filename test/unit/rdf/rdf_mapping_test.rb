require 'test_helper'

class RdfMappingTest < ActiveSupport::TestCase
  PRED        = 'http://healthdataportal.eu/ns/health#healthCategory'.freeze
  XSD_BOOLEAN = 'http://www.w3.org/2001/XMLSchema#boolean'.freeze
  XSD_INTEGER = 'http://www.w3.org/2001/XMLSchema#integer'.freeze

  # --- plain literal (default) ---

  test 'literal value_type returns plain RDF::Literal' do
    mapping = Seek::Rdf::RdfMapping.new(predicate: PRED, value_type: 'literal')
    result = mapping.build_rdf_object('COVID-19 registry')
    assert_kind_of RDF::Literal, result
    assert_equal 'COVID-19 registry', result.to_s
    assert_nil result.language
  end

  test 'nil value_type defaults to plain literal' do
    mapping = Seek::Rdf::RdfMapping.new(predicate: PRED, value_type: nil)
    assert_equal 'literal', mapping.value_type
    result = mapping.build_rdf_object('hello')
    assert_kind_of RDF::Literal, result
  end

  test 'unrecognised value_type defaults to plain literal' do
    mapping = Seek::Rdf::RdfMapping.new(predicate: PRED, value_type: 'nonsense')
    assert_equal 'literal', mapping.value_type
  end

  # --- lang_literal ---

  test 'lang_literal returns language-tagged RDF::Literal' do
    mapping = Seek::Rdf::RdfMapping.new(predicate: PRED, value_type: 'lang_literal')
    result = mapping.build_rdf_object('Adult patients aged 18-65')
    assert_kind_of RDF::Literal, result
    assert_equal :en, result.language
    assert_equal 'Adult patients aged 18-65', result.to_s
  end

  # --- typed_literal ---

  test 'typed_literal with datatype returns typed RDF::Literal' do
    mapping = Seek::Rdf::RdfMapping.new(predicate: PRED, value_type: 'typed_literal', datatype: XSD_BOOLEAN)
    result = mapping.build_rdf_object('true')
    assert_kind_of RDF::Literal, result
    assert_equal RDF::URI(XSD_BOOLEAN), result.datatype
    assert_equal 'true', result.to_s
  end

  test 'typed_literal without datatype falls back to plain literal' do
    mapping = Seek::Rdf::RdfMapping.new(predicate: PRED, value_type: 'typed_literal', datatype: nil)
    result = mapping.build_rdf_object('42')
    assert_kind_of RDF::Literal, result
  end

  test 'typed_literal integer datatype' do
    mapping = Seek::Rdf::RdfMapping.new(predicate: PRED, value_type: 'typed_literal', datatype: XSD_INTEGER)
    result = mapping.build_rdf_object('18')
    assert_equal RDF::URI(XSD_INTEGER), result.datatype
  end

  # --- iri ---

  test 'iri value_type returns RDF::URI for valid IRI' do
    valid_iri = 'http://13.81.34.152:1101/resource/authority/healthcategories/EHRS'
    mapping = Seek::Rdf::RdfMapping.new(predicate: PRED, value_type: 'iri')
    result = mapping.build_rdf_object(valid_iri)
    assert_instance_of RDF::URI, result
    assert_equal valid_iri, result.to_s
  end

  test 'iri value_type falls back to plain literal for invalid IRI' do
    mapping = Seek::Rdf::RdfMapping.new(predicate: PRED, value_type: 'iri')
    result = mapping.build_rdf_object('not a valid IRI !!!')
    assert_kind_of RDF::Literal, result
    assert_equal 'not a valid IRI !!!', result.to_s
  end

  # --- nil / blank values ---

  test 'returns nil for nil value' do
    mapping = Seek::Rdf::RdfMapping.new(predicate: PRED)
    assert_nil mapping.build_rdf_object(nil)
  end

  test 'returns nil for empty string' do
    mapping = Seek::Rdf::RdfMapping.new(predicate: PRED)
    assert_nil mapping.build_rdf_object('')
  end

  test 'returns nil for whitespace-only string' do
    mapping = Seek::Rdf::RdfMapping.new(predicate: PRED)
    assert_nil mapping.build_rdf_object('   ')
  end

  # --- predicate ---

  test 'predicate is an RDF::URI' do
    mapping = Seek::Rdf::RdfMapping.new(predicate: PRED)
    assert_instance_of RDF::URI, mapping.predicate
    assert_equal PRED, mapping.predicate.to_s
  end

  # --- from_attribute reads from sample_attribute_type ---

  test 'from_attribute reads rdf_value_type and rdf_datatype from sample_attribute_type' do
    sat = SampleAttributeType.new(
      title: 'HealthDCAT Boolean',
      base_type: Seek::Samples::BaseType::BOOLEAN,
      regexp: '.*',
      rdf_value_type: 'typed_literal',
      rdf_datatype: XSD_BOOLEAN
    )
    attr = ExtendedMetadataAttribute.new(pid: PRED, sample_attribute_type: sat)
    mapping = Seek::Rdf::RdfMapping.from_attribute(attr)
    assert_equal PRED, mapping.predicate.to_s
    assert_equal 'typed_literal', mapping.value_type
    assert_equal RDF::URI(XSD_BOOLEAN), mapping.datatype
  end

  test 'from_attribute with no rdf_value_type on sample_attribute_type defaults to literal' do
    sat = SampleAttributeType.new(
      title: 'Plain String',
      base_type: Seek::Samples::BaseType::STRING,
      regexp: '.*'
    )
    attr = ExtendedMetadataAttribute.new(pid: PRED, sample_attribute_type: sat)
    mapping = Seek::Rdf::RdfMapping.from_attribute(attr)
    assert_equal 'literal', mapping.value_type
  end

  test 'from_attribute works with SampleAttribute as well' do
    sat = SampleAttributeType.new(
      title: 'HealthDCAT IRI',
      base_type: Seek::Samples::BaseType::STRING,
      regexp: '.*',
      rdf_value_type: 'iri'
    )
    attr = SampleAttribute.new(pid: PRED, sample_attribute_type: sat)
    mapping = Seek::Rdf::RdfMapping.from_attribute(attr)
    assert_equal 'iri', mapping.value_type
  end
end
