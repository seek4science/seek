require 'test_helper'

class ExtendedMetadataEmitterTest < ActiveSupport::TestCase
  PRED         = 'http://healthdataportal.eu/ns/health#healthCategory'.freeze
  XSD_INTEGER  = 'http://www.w3.org/2001/XMLSchema#integer'.freeze
  RESOURCE_URI = 'https://seek.example.org/data_files/1'.freeze
  SEEKH_BASE   = 'https://seek4science.org/vocab/seekh#'.freeze

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  def build_sat(rdf_value_type: nil, rdf_datatype: nil)
    SampleAttributeType.new(
      title: 'String',
      base_type: Seek::Samples::BaseType::STRING,
      regexp: '.*',
      rdf_value_type: rdf_value_type,
      rdf_datatype: rdf_datatype
    )
  end

  def build_attr(title:, pid: PRED, rdf_value_type: nil, rdf_datatype: nil)
    ExtendedMetadataAttribute.new(
      title: title,
      pid: pid,
      sample_attribute_type: build_sat(rdf_value_type: rdf_value_type, rdf_datatype: rdf_datatype)
    )
  end

  def build_em(attr_values)
    emt = ExtendedMetadataType.new(title: 'Test EMT', supported_type: 'DataFile')
    attr_values.each_key { |attr| emt.extended_metadata_attributes << attr }
    em = ExtendedMetadata.new(extended_metadata_type: emt)
    attr_values.each { |attr, value| em.set_attribute_value(attr.title, value) }
    em
  end

  def stub_resource(ext_meta)
    OpenStruct.new(
      extended_metadata: ext_meta,
      rdf_resource: RDF::URI(RESOURCE_URI)
    )
  end

  def emit(resource)
    graph = RDF::Graph.new
    Seek::Rdf::ExtendedMetadataEmitter.new(resource, graph).emit
  end

  def triples_for(graph, predicate_uri)
    graph.query([RDF::URI(RESOURCE_URI), RDF::URI(predicate_uri), nil]).map(&:object)
  end

  # ---------------------------------------------------------------------------
  # tests
  # ---------------------------------------------------------------------------

  test 'emits plain literal for default (nil) rdf_value_type' do
    attr  = build_attr(title: 'label')
    graph = emit(stub_resource(build_em({ attr => 'COVID-19 registry' })))

    objects = triples_for(graph, PRED)
    assert_equal 1, objects.size
    assert_kind_of RDF::Literal, objects.first
    assert_equal 'COVID-19 registry', objects.first.to_s
  end

  test 'emits typed literal when rdf_value_type is typed_literal' do
    attr  = build_attr(title: 'count', rdf_value_type: 'typed_literal', rdf_datatype: XSD_INTEGER)
    graph = emit(stub_resource(build_em({ attr => '5000' })))

    objects = triples_for(graph, PRED)
    assert_equal 1, objects.size
    assert_equal RDF::URI(XSD_INTEGER), objects.first.datatype
  end

  test 'emits language-tagged literal when rdf_value_type is lang_literal' do
    attr  = build_attr(title: 'coverage', rdf_value_type: 'lang_literal')
    graph = emit(stub_resource(build_em({ attr => 'Adults aged 18-65' })))

    objects = triples_for(graph, PRED)
    assert_equal 1, objects.size
    assert_equal :en, objects.first.language
  end

  test 'emits RDF::URI when rdf_value_type is iri and value is valid' do
    valid_iri = 'http://example.org/categories/EHRS'
    attr      = build_attr(title: 'category', rdf_value_type: 'iri')
    graph     = emit(stub_resource(build_em({ attr => valid_iri })))

    objects = triples_for(graph, PRED)
    assert_equal 1, objects.size
    assert_instance_of RDF::URI, objects.first
    assert_equal valid_iri, objects.first.to_s
  end

  test 'falls back to plain literal when iri value is invalid' do
    attr  = build_attr(title: 'category', rdf_value_type: 'iri')
    graph = emit(stub_resource(build_em({ attr => 'not a valid IRI !!!' })))

    objects = triples_for(graph, PRED)
    assert_equal 1, objects.size
    assert_kind_of RDF::Literal, objects.first
  end

  test 'skips nil values' do
    attr  = build_attr(title: 'label')
    graph = emit(stub_resource(build_em({ attr => nil })))
    assert_equal 0, graph.count
  end

  test 'skips blank values' do
    attr  = build_attr(title: 'label')
    graph = emit(stub_resource(build_em({ attr => '' })))
    assert_equal 0, graph.count
  end

  test 'emits one triple per element for array values' do
    attr = build_attr(title: 'label')
    em   = build_em({ attr => nil })
    em.set_attribute_value('label', %w[alpha beta gamma])
    graph = emit(stub_resource(em))

    objects = triples_for(graph, PRED)
    assert_equal 3, objects.size
    assert_equal %w[alpha beta gamma], objects.map(&:to_s).sort
  end

  test 'falls back to seekh namespace when pid is absent' do
    attr  = build_attr(title: 'population coverage', pid: nil)
    graph = emit(stub_resource(build_em({ attr => 'adults' })))

    expected_pred = "#{SEEKH_BASE}population_coverage"
    objects = triples_for(graph, expected_pred)
    assert_equal 1, objects.size
    assert_equal 'adults', objects.first.to_s
  end

  test 'returns graph unchanged when resource has no extended metadata' do
    resource = OpenStruct.new(extended_metadata: nil, rdf_resource: RDF::URI(RESOURCE_URI))
    graph    = emit(resource)
    assert_equal 0, graph.count
  end

  # ---------------------------------------------------------------------------
  # blank node (linked_extended_metadata) tests
  # ---------------------------------------------------------------------------

  def build_linked_sat
    SampleAttributeType.new(
      title: 'LinkedEMT',
      base_type: Seek::Samples::BaseType::LINKED_EXTENDED_METADATA,
      regexp: '.*'
    )
  end

  def build_period_of_time_emt
    start_attr = build_attr(title: 'startDate', pid: 'http://www.w3.org/ns/dcat#startDate')
    end_attr   = build_attr(title: 'endDate',   pid: 'http://www.w3.org/ns/dcat#endDate')
    emt = ExtendedMetadataType.new(title: 'PeriodOfTime', supported_type: 'DataFile')
    emt.extended_metadata_attributes << start_attr
    emt.extended_metadata_attributes << end_attr
    emt
  end

  def build_retention_attr(linked_emt)
    ExtendedMetadataAttribute.new(
      title: 'retentionPeriod',
      pid: 'http://healthdataportal.eu/ns/health#retentionPeriod',
      sample_attribute_type: build_linked_sat,
      linked_extended_metadata_type: linked_emt
    )
  end

  test 'emits blank node for linked_extended_metadata attribute' do
    linked_emt     = build_period_of_time_emt
    retention_attr = build_retention_attr(linked_emt)
    em             = build_em({ retention_attr => { 'startDate' => '2020-01-01', 'endDate' => '2025-12-31' } })
    graph          = emit(stub_resource(em))

    retention_pred = RDF::URI('http://healthdataportal.eu/ns/health#retentionPeriod')
    blank_nodes    = graph.query([RDF::URI(RESOURCE_URI), retention_pred, nil]).map(&:object)
    assert_equal 1, blank_nodes.size
    assert blank_nodes.first.anonymous?
  end

  test 'blank node has correct rdf:type for known predicate' do
    linked_emt     = build_period_of_time_emt
    retention_attr = build_retention_attr(linked_emt)
    em             = build_em({ retention_attr => { 'startDate' => '2020-01-01', 'endDate' => '2025-12-31' } })
    graph          = emit(stub_resource(em))

    retention_pred  = RDF::URI('http://healthdataportal.eu/ns/health#retentionPeriod')
    blank_node      = graph.query([RDF::URI(RESOURCE_URI), retention_pred, nil]).first.object
    types           = graph.query([blank_node, RDF.type, nil]).map { |s| s.object.to_s }
    assert_includes types, 'http://purl.org/dc/terms/PeriodOfTime'
  end

  test 'blank node contains nested attribute triples' do
    linked_emt     = build_period_of_time_emt
    retention_attr = build_retention_attr(linked_emt)
    em             = build_em({ retention_attr => { 'startDate' => '2020-01-01', 'endDate' => '2025-12-31' } })
    graph          = emit(stub_resource(em))

    retention_pred = RDF::URI('http://healthdataportal.eu/ns/health#retentionPeriod')
    blank_node     = graph.query([RDF::URI(RESOURCE_URI), retention_pred, nil]).first.object
    start_values   = graph.query([blank_node, RDF::URI('http://www.w3.org/ns/dcat#startDate'), nil]).map { |s| s.object.to_s }
    end_values     = graph.query([blank_node, RDF::URI('http://www.w3.org/ns/dcat#endDate'), nil]).map { |s| s.object.to_s }
    assert_equal ['2020-01-01'], start_values
    assert_equal ['2025-12-31'], end_values
  end

  test 'skips blank node when nested data value is not set' do
    linked_emt     = build_period_of_time_emt
    retention_attr = build_retention_attr(linked_emt)
    # Build EM with the attribute present but no value assigned (stays nil in Data)
    emt = ExtendedMetadataType.new(title: 'Test EMT', supported_type: 'DataFile')
    emt.extended_metadata_attributes << retention_attr
    em    = ExtendedMetadata.new(extended_metadata_type: emt)
    graph = emit(stub_resource(em))
    assert_equal 0, graph.count
  end

  test 'skips blank node when all nested values are blank' do
    linked_emt     = build_period_of_time_emt
    retention_attr = build_retention_attr(linked_emt)
    em             = build_em({ retention_attr => { 'startDate' => '', 'endDate' => '' } })
    graph          = emit(stub_resource(em))
    assert_equal 0, graph.count
  end

  test 'blank node has no rdf:type for unknown predicate' do
    linked_emt = build_period_of_time_emt
    attr       = ExtendedMetadataAttribute.new(
      title: 'customNested',
      pid: 'http://example.org/unknownPred',
      sample_attribute_type: build_linked_sat,
      linked_extended_metadata_type: linked_emt
    )
    em    = build_em({ attr => { 'startDate' => '2024-01-01', 'endDate' => '2024-12-31' } })
    graph = emit(stub_resource(em))

    blank_node = graph.query([RDF::URI(RESOURCE_URI), RDF::URI('http://example.org/unknownPred'), nil]).first.object
    types = graph.query([blank_node, RDF.type, nil]).to_a
    assert_empty types
  end
end
