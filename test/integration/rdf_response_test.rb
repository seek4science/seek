require 'test_helper'

class RdfResponseTest < ActionDispatch::IntegrationTest
  test 'rdf mime types' do
    project = FactoryBot.create :project
    graph = RDF::Graph.new do |g|
      RDF::Reader.for(:ttl).new(project.to_rdf) { |reader| g << reader }
    end
    statement_count = graph.statements.count

    get project_url(project), headers: { 'Accept' => 'application/rdf' }
    assert_equal 'text/turtle', @response.media_type
    graph = RDF::Graph.new do |g|
      RDF::Reader.for(:ttl).new(@response.body) { |reader| g << reader }
    end
    assert_equal statement_count, graph.statements.count

    get project_url(project), headers: { 'Accept' => 'application/x-turtle' }
    assert_equal 'text/turtle', @response.media_type
    graph = RDF::Graph.new do |g|
      RDF::Reader.for(:ttl).new(@response.body) { |reader| g << reader }
    end
    assert_equal statement_count, graph.statements.count

    get project_url(project), headers: { 'Accept' => 'text/turtle' }
    assert_equal 'text/turtle', @response.media_type
    graph = RDF::Graph.new do |g|
      RDF::Reader.for(:ttl).new(@response.body) { |reader| g << reader }
    end
    assert_equal statement_count, graph.statements.count
  end

  # ---------------------------------------------------------------------------
  # DCAT / HealthDCAT-AP HTTP-level assertions (Cycle 6)
  # ---------------------------------------------------------------------------

  test 'data file turtle response contains dcat:Dataset type triple' do
    data_file = FactoryBot.create(:public_data_file)

    get data_file_url(data_file), headers: { 'Accept' => 'text/turtle' }

    assert_response :success
    assert_equal 'text/turtle', @response.media_type

    graph = parse_turtle(@response.body)
    subject = RDF::URI(data_file_url(data_file))
    types   = graph.query([subject, RDF.type, nil]).map { |s| s.object.to_s }
    assert_includes types, 'http://www.w3.org/ns/dcat#Dataset',
                    'Expected dcat:Dataset type triple in DataFile Turtle response'
  end

  test 'data file turtle response contains dcat:Distribution blank node' do
    data_file = FactoryBot.create(:public_data_file)

    get data_file_url(data_file), headers: { 'Accept' => 'text/turtle' }

    graph    = parse_turtle(@response.body)
    subject  = RDF::URI(data_file_url(data_file))
    dist_obj = graph.query([subject, RDF::URI('http://www.w3.org/ns/dcat#distribution'), nil]).map(&:object)
    assert_equal 1, dist_obj.size, 'Expected exactly one dcat:distribution blank node'
    assert dist_obj.first.anonymous?, 'Expected dcat:distribution object to be a blank node'
  end

  test 'data file turtle response has dcat:downloadURL in Distribution' do
    data_file = FactoryBot.create(:public_data_file)

    get data_file_url(data_file), headers: { 'Accept' => 'text/turtle' }

    graph     = parse_turtle(@response.body)
    subject   = RDF::URI(data_file_url(data_file))
    dist_node = graph.query([subject, RDF::URI('http://www.w3.org/ns/dcat#distribution'), nil]).first.object
    dl_uris   = graph.query([dist_node, RDF::URI('http://www.w3.org/ns/dcat#downloadURL'), nil]).map { |s| s.object.to_s }
    assert_equal 1, dl_uris.size
    assert_match %r{/data_files/\d+/download}, dl_uris.first
  end

  test 'data file turtle response includes dcat and dcterms prefixes' do
    data_file = FactoryBot.create(:public_data_file)

    get data_file_url(data_file), headers: { 'Accept' => 'text/turtle' }

    body = @response.body
    # dcat: is always emitted (dcat:Dataset type + dcat:Distribution)
    assert_match '@prefix dcat:', body
    # dcterms: is always emitted (title, description from rdf_mappings.csv)
    assert_match '@prefix dcterms:', body
  end

  test 'ns_prefixes includes all healthdcat vocabularies' do
    data_file = FactoryBot.create(:public_data_file)
    prefixes  = data_file.ns_prefixes
    assert prefixes.key?('healthdcatap'), 'Expected healthdcatap prefix'
    assert prefixes.key?('seekh'),        'Expected seekh prefix'
    assert prefixes.key?('dpv'),          'Expected dpv prefix'
    assert prefixes.key?('dcat'),         'Expected dcat prefix'
  end

  test 'assay turtle response contains dcat:Dataset type triple' do
    assay = FactoryBot.create(:public_assay)

    get assay_url(assay), headers: { 'Accept' => 'text/turtle' }

    assert_response :success
    graph  = parse_turtle(@response.body)
    types  = graph.query([RDF::URI(assay_url(assay)), RDF.type, nil]).map { |s| s.object.to_s }
    assert_includes types, 'http://www.w3.org/ns/dcat#Dataset'
  end

  test 'json-ld response for data file contains dcat:Dataset type' do
    data_file = FactoryBot.create(:public_data_file)

    get data_file_url(data_file), headers: { 'Accept' => 'application/ld+json' }

    assert_response :success
    body  = JSON.parse(@response.body)
    types = Array(body['@type'])
    # JSON-LD compact form may be prefixed ("dcat:Dataset") or full IRI
    assert(types.any? { |t| t.include?('Dataset') },
           "Expected @type to include Dataset, got: #{types.inspect}")
  end

  # ---------------------------------------------------------------------------
  # /dcat endpoint (Cycle 9.5)
  # ---------------------------------------------------------------------------

  test '/dcat endpoint returns turtle with dcat:Dataset type' do
    data_file = FactoryBot.create(:public_data_file)

    get dcat_data_file_url(data_file), headers: { 'Accept' => 'text/turtle' }

    assert_response :success
    assert_equal 'text/turtle', @response.media_type
    graph = parse_turtle(@response.body)
    types = graph.query([RDF::URI(data_file_url(data_file)), RDF.type, nil]).map { |s| s.object.to_s }
    assert_includes types, 'http://www.w3.org/ns/dcat#Dataset'
  end

  test '/dcat endpoint returns DCAT JSON-LD with jerm and dcat context keys' do
    data_file = FactoryBot.create(:public_data_file)

    get dcat_data_file_url(data_file), headers: { 'Accept' => 'application/ld+json' }

    assert_response :success
    assert_equal 'application/ld+json', @response.media_type
    body = JSON.parse(@response.body)
    context = body['@context']
    assert context.is_a?(Hash), 'Expected DCAT JSON-LD @context to be a namespace hash, not a schema.org string'
    assert context.key?('dcat'),  'Expected dcat key in @context'
    assert context.key?('jerm'),  'Expected jerm key in @context'
  end

  test 'show action application/ld+json still returns bioschemas format' do
    data_file = FactoryBot.create(:public_data_file)

    get data_file_url(data_file), headers: { 'Accept' => 'application/ld+json' }

    assert_response :success
    body    = JSON.parse(@response.body)
    context = body['@context']
    assert_equal 'https://schema.org', context, 'Expected show action to still return Schema.org Bioschemas format'
  end

  test '/dcat endpoint for assay returns turtle with dcat:Dataset type' do
    assay = FactoryBot.create(:public_assay)

    get dcat_assay_url(assay), headers: { 'Accept' => 'text/turtle' }

    assert_response :success
    graph = parse_turtle(@response.body)
    types = graph.query([RDF::URI(assay_url(assay)), RDF.type, nil]).map { |s| s.object.to_s }
    assert_includes types, 'http://www.w3.org/ns/dcat#Dataset'
  end

  private

  def parse_turtle(body)
    RDF::Graph.new do |graph|
      RDF::Reader.for(:ttl).new(body) { |reader| graph << reader }
    end
  end
end
