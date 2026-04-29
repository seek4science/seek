require 'test_helper'

# Integration tests for the HealthDCAT-AP example DataFile.
# These tests build an in-memory DataFile with HealthDCAT-AP extended metadata
# (matching the COVID-19 Patient Registry seed) and assert that the RDF output
# contains the expected triples — serving as regression fixtures for Cycle 8.
class RdfHealthdcatExampleTest < ActiveSupport::TestCase
  HDCAT_NS = 'http://healthdataportal.eu/ns/health#'.freeze
  DPV_NS   = 'https://w3id.org/dpv#'.freeze
  DCT_NS   = 'http://purl.org/dc/terms/'.freeze
  DCAT_NS  = 'http://www.w3.org/ns/dcat#'.freeze
  XSD_NS   = 'http://www.w3.org/2001/XMLSchema#'.freeze

  # -------------------------------------------------------------------------
  # Helpers
  # -------------------------------------------------------------------------

  def build_iri_sat
    SampleAttributeType.find_or_create_by!(title: 'URI - HealthDCAT Test') do |sat|
      sat.base_type = Seek::Samples::BaseType::STRING
      sat.regexp = '.*'
      sat.rdf_value_type = 'iri'
    end
  end

  def build_int_sat
    SampleAttributeType.find_or_initialize_by(title: 'Integer').tap do |sat|
      sat.base_type = Seek::Samples::BaseType::INTEGER
      sat.regexp = '.*'
      sat.save!(validate: false)
    end
  end

  def build_bool_sat
    SampleAttributeType.find_or_initialize_by(title: 'Boolean').tap do |sat|
      sat.base_type = Seek::Samples::BaseType::BOOLEAN
      sat.regexp = '.*'
      sat.save!(validate: false)
    end
  end

  def build_text_sat
    SampleAttributeType.find_or_initialize_by(title: 'Text').tap do |sat|
      sat.base_type = Seek::Samples::BaseType::TEXT
      sat.regexp = '.*'
      sat.save!(validate: false)
    end
  end

  def build_linked_sat
    SampleAttributeType.find_or_initialize_by(title: 'Linked Extended Metadata').tap do |sat|
      sat.base_type = Seek::Samples::BaseType::LINKED_EXTENDED_METADATA
      sat.regexp = '.*'
      sat.save!(validate: false)
    end
  end

  def build_healthdcat_emt
    string_sat = SampleAttributeType.find_or_initialize_by(title: 'String').tap do |sat|
      sat.base_type = Seek::Samples::BaseType::STRING
      sat.regexp = '.*'
      sat.save!(validate: false)
    end

    # Inner retention period EMT — must be persisted for linked validation
    retention_emt = ExtendedMetadataType.find_or_initialize_by(
      title: 'HealthDCAT Retention Period Test', supported_type: 'ExtendedMetadata'
    )
    if retention_emt.new_record?
      retention_emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
        title: 'start_date', pid: "#{DCAT_NS}startDate", sample_attribute_type: string_sat
      )
      retention_emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
        title: 'end_date', pid: "#{DCAT_NS}endDate", sample_attribute_type: string_sat
      )
      retention_emt.save!
    end

    emt = ExtendedMetadataType.find_or_initialize_by(
      title: 'HealthDCAT-AP Health Dataset Test', supported_type: 'DataFile'
    )
    if emt.new_record?
      emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
        title: 'health_category', pid: "#{HDCAT_NS}healthCategory", sample_attribute_type: build_iri_sat
      )
      emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
        title: 'population_coverage', pid: "#{HDCAT_NS}populationCoverage", sample_attribute_type: build_text_sat
      )
      emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
        title: 'min_typical_age', pid: "#{HDCAT_NS}minimumTypicalAge", sample_attribute_type: build_int_sat
      )
      emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
        title: 'max_typical_age', pid: "#{HDCAT_NS}maximumTypicalAge", sample_attribute_type: build_int_sat
      )
      emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
        title: 'trusted_data_holder', pid: "#{HDCAT_NS}trusteddataholder", sample_attribute_type: build_bool_sat
      )
      emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
        title: 'personal_data_categories', pid: "#{DPV_NS}hasPersonalData", sample_attribute_type: build_iri_sat
      )
      emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
        title: 'access_rights', pid: "#{DCT_NS}accessRights", sample_attribute_type: build_iri_sat
      )
      emt.extended_metadata_attributes << ExtendedMetadataAttribute.new(
        title: 'retention_period', pid: "#{HDCAT_NS}retentionPeriod",
        sample_attribute_type: build_linked_sat, linked_extended_metadata_type: retention_emt
      )
      emt.save!
    end
    [emt, retention_emt]
  end

  def build_data_file_with_healthdcat
    emt, _retention_emt = build_healthdcat_emt

    em = ExtendedMetadata.new(extended_metadata_type: emt)
    em.set_attribute_value('health_category',
                           'http://13.81.34.152:1101/resource/authority/healthcategories/INFECTIOUS_DISEASE')
    em.set_attribute_value('population_coverage', 'Adult hospitalised COVID-19 patients aged 18-65')
    em.set_attribute_value('min_typical_age', 18)
    em.set_attribute_value('max_typical_age', 65)
    em.set_attribute_value('trusted_data_holder', true)
    em.set_attribute_value('personal_data_categories', 'https://w3id.org/dpv/dpv-pd#HealthRecord')
    em.set_attribute_value('access_rights',
                           'http://publications.europa.eu/resource/authority/access-right/RESTRICTED')
    em.set_attribute_value('retention_period', { 'start_date' => '2020-03-01', 'end_date' => '2030-12-31' })

    FactoryBot.create(:public_data_file,
                      title: 'COVID-19 Patient Registry',
                      description: 'Clinical data of hospitalised COVID-19 patients.',
                      extended_metadata: em)
  end

  def parse_turtle(ttl)
    RDF::Graph.new do |g|
      RDF::Reader.for(:ttl).new(ttl) { |r| g << r }
    end
  end

  # -------------------------------------------------------------------------
  # Tests
  # -------------------------------------------------------------------------

  test 'healthdcat data file emits dcat:Dataset type triple' do
    df    = build_data_file_with_healthdcat
    graph = parse_turtle(df.to_rdf)
    types = graph.query([RDF::URI(df.rdf_resource.to_s), RDF.type, nil]).map { |s| s.object.to_s }
    assert_includes types, "#{DCAT_NS}Dataset"
  end

  test 'healthdcat data file emits healthdcatap:healthCategory as IRI' do
    df    = build_data_file_with_healthdcat
    graph = parse_turtle(df.to_rdf)
    sub   = RDF::URI(df.rdf_resource.to_s)
    pred  = RDF::URI("#{HDCAT_NS}healthCategory")
    objs  = graph.query([sub, pred, nil]).map(&:object)
    assert_equal 1, objs.size, 'Expected one healthCategory triple'
    assert objs.first.uri?, "Expected healthCategory object to be an IRI, got #{objs.first.class}"
    assert_equal 'http://13.81.34.152:1101/resource/authority/healthcategories/INFECTIOUS_DISEASE',
                 objs.first.to_s
  end

  test 'healthdcat data file emits healthdcatap:populationCoverage as literal' do
    df    = build_data_file_with_healthdcat
    graph = parse_turtle(df.to_rdf)
    sub   = RDF::URI(df.rdf_resource.to_s)
    pred  = RDF::URI("#{HDCAT_NS}populationCoverage")
    objs  = graph.query([sub, pred, nil]).map(&:object)
    assert_equal 1, objs.size
    assert objs.first.literal?
    assert_match(/COVID-19/, objs.first.to_s)
  end

  test 'healthdcat data file emits dpv:hasPersonalData as IRI' do
    df    = build_data_file_with_healthdcat
    graph = parse_turtle(df.to_rdf)
    sub   = RDF::URI(df.rdf_resource.to_s)
    pred  = RDF::URI("#{DPV_NS}hasPersonalData")
    objs  = graph.query([sub, pred, nil]).map(&:object)
    assert_equal 1, objs.size
    assert objs.first.uri?, 'Expected dpv:hasPersonalData to be an IRI'
    assert_equal 'https://w3id.org/dpv/dpv-pd#HealthRecord', objs.first.to_s
  end

  test 'healthdcat data file emits dct:accessRights as IRI' do
    df    = build_data_file_with_healthdcat
    graph = parse_turtle(df.to_rdf)
    sub   = RDF::URI(df.rdf_resource.to_s)
    pred  = RDF::URI("#{DCT_NS}accessRights")
    objs  = graph.query([sub, pred, nil]).map(&:object)
    assert_equal 1, objs.size
    assert objs.first.uri?
    assert_match(/RESTRICTED/, objs.first.to_s)
  end

  test 'healthdcat data file emits retentionPeriod as blank node with start/end dates' do
    df    = build_data_file_with_healthdcat
    graph = parse_turtle(df.to_rdf)
    sub   = RDF::URI(df.rdf_resource.to_s)
    pred  = RDF::URI("#{HDCAT_NS}retentionPeriod")
    nodes = graph.query([sub, pred, nil]).map(&:object)
    assert_equal 1, nodes.size, 'Expected one retentionPeriod blank node'
    bn = nodes.first
    assert bn.anonymous?, 'Expected retentionPeriod to be a blank node'

    start_dates = graph.query([bn, RDF::URI("#{DCAT_NS}startDate"), nil]).map { |s| s.object.to_s }
    end_dates   = graph.query([bn, RDF::URI("#{DCAT_NS}endDate"), nil]).map { |s| s.object.to_s }
    assert_includes start_dates, '2020-03-01'
    assert_includes end_dates, '2030-12-31'
  end

  test 'healthdcat data file emits jerm type triple alongside dcat:Dataset' do
    df    = build_data_file_with_healthdcat
    graph = parse_turtle(df.to_rdf)
    sub   = RDF::URI(df.rdf_resource.to_s)
    types = graph.query([sub, RDF.type, nil]).map { |s| s.object.to_s }
    assert_includes types, "#{DCAT_NS}Dataset", 'dcat:Dataset missing'
    assert(types.any? { |t| t.include?('jermontology') }, 'JERM type triple missing')
  end

  test 'healthdcat turtle output includes healthdcatap prefix declaration' do
    df  = build_data_file_with_healthdcat
    ttl = df.to_rdf
    assert_match '@prefix healthdcatap:', ttl
    assert_match '@prefix dpv:', ttl
  end

  test 'json-ld output for healthdcat data file contains healthCategory' do
    df   = build_data_file_with_healthdcat
    json = JSON.parse(df.to_json_ld)
    assert json.to_s.include?('healthCategory') || json.to_s.include?(HDCAT_NS),
           'Expected healthCategory in JSON-LD output'
  end
end
