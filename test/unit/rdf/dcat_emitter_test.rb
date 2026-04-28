require 'test_helper'

class DcatEmitterTest < ActiveSupport::TestCase
  RESOURCE_URI  = 'https://seek.example.org/data_files/1'.freeze
  DCAT_DATASET  = 'http://www.w3.org/ns/dcat#Dataset'.freeze
  DCAT_RESOURCE = 'http://www.w3.org/ns/dcat#Resource'.freeze
  DCAT_DIST     = 'http://www.w3.org/ns/dcat#Distribution'.freeze
  DCAT_DIST_P   = 'http://www.w3.org/ns/dcat#distribution'.freeze
  DCAT_DL_URL   = 'http://www.w3.org/ns/dcat#downloadURL'.freeze
  DCAT_ACCESS   = 'http://www.w3.org/ns/dcat#accessURL'.freeze
  DCAT_BYTESIZE = 'http://www.w3.org/ns/dcat#byteSize'.freeze
  DCT_FORMAT    = 'http://purl.org/dc/terms/format'.freeze

  # ---------------------------------------------------------------------------
  # helpers
  # ---------------------------------------------------------------------------

  def klass_stub(name)
    Struct.new(:name).new(name)
  end

  def stub_blob(file_size: nil, content_type: nil, empty: false)
    OpenStruct.new(
      file_size: file_size,
      content_type: content_type,
      no_content?: empty
    )
  end

  def stub_resource(class_name, blob: nil)
    resource = OpenStruct.new(
      rdf_resource: RDF::URI(RESOURCE_URI),
      content_blob: blob
    )
    klass = klass_stub(class_name)
    resource.define_singleton_method(:class) { klass }
    resource
  end

  def emit(resource)
    graph = RDF::Graph.new
    Seek::Rdf::DcatEmitter.new(resource, graph).emit
  end

  def types_for(graph)
    graph.query([RDF::URI(RESOURCE_URI), RDF.type, nil]).map(&:object).map(&:to_s)
  end

  # ---------------------------------------------------------------------------
  # DCAT type assertions
  # ---------------------------------------------------------------------------

  test 'emits dcat:Dataset for DataFile' do
    graph = emit(stub_resource('DataFile'))
    assert_includes types_for(graph), DCAT_DATASET
  end

  test 'emits dcat:Dataset for Assay' do
    graph = emit(stub_resource('Assay'))
    assert_includes types_for(graph), DCAT_DATASET
  end

  test 'emits dcat:Resource for Investigation' do
    graph = emit(stub_resource('Investigation'))
    assert_includes types_for(graph), DCAT_RESOURCE
  end

  test 'emits dcat:Resource for Study' do
    graph = emit(stub_resource('Study'))
    assert_includes types_for(graph), DCAT_RESOURCE
  end

  test 'emits no DCAT type for unmapped class' do
    graph = emit(stub_resource('Publication'))
    assert_empty types_for(graph)
  end

  # ---------------------------------------------------------------------------
  # dcat:Distribution
  # ---------------------------------------------------------------------------

  test 'emits Distribution blank node when content_blob is present' do
    blob  = stub_blob(file_size: 1024, content_type: 'text/csv')
    graph = emit(stub_resource('DataFile', blob: blob))

    dist_links = graph.query([RDF::URI(RESOURCE_URI), RDF::URI(DCAT_DIST_P), nil]).map(&:object)
    assert_equal 1, dist_links.size
    dist = dist_links.first
    assert dist.anonymous?

    types = graph.query([dist, RDF.type, nil]).map { |s| s.object.to_s }
    assert_includes types, DCAT_DIST
  end

  test 'emits accessURL and downloadURL pointing to /download' do
    blob  = stub_blob(file_size: 512, content_type: 'application/pdf')
    graph = emit(stub_resource('DataFile', blob: blob))

    dist = graph.query([RDF::URI(RESOURCE_URI), RDF::URI(DCAT_DIST_P), nil]).first.object
    download_uris = graph.query([dist, RDF::URI(DCAT_DL_URL), nil]).map { |s| s.object.to_s }
    access_uris   = graph.query([dist, RDF::URI(DCAT_ACCESS), nil]).map { |s| s.object.to_s }

    assert_equal ["#{RESOURCE_URI}/download"], download_uris
    assert_equal ["#{RESOURCE_URI}/download"], access_uris
  end

  test 'emits byteSize as xsd:decimal when file_size is positive' do
    blob  = stub_blob(file_size: 2048, content_type: 'text/csv')
    graph = emit(stub_resource('DataFile', blob: blob))

    dist        = graph.query([RDF::URI(RESOURCE_URI), RDF::URI(DCAT_DIST_P), nil]).first.object
    byte_values = graph.query([dist, RDF::URI(DCAT_BYTESIZE), nil]).map(&:object)
    assert_equal 1, byte_values.size
    assert_equal RDF::URI('http://www.w3.org/2001/XMLSchema#decimal'), byte_values.first.datatype
    assert_equal '2048', byte_values.first.to_s
  end

  test 'omits byteSize when file_size is zero' do
    blob  = stub_blob(file_size: 0, content_type: 'text/csv')
    graph = emit(stub_resource('DataFile', blob: blob))

    dist        = graph.query([RDF::URI(RESOURCE_URI), RDF::URI(DCAT_DIST_P), nil]).first.object
    byte_values = graph.query([dist, RDF::URI(DCAT_BYTESIZE), nil]).to_a
    assert_empty byte_values
  end

  test 'emits dct:format when content_type is present' do
    blob  = stub_blob(file_size: 100, content_type: 'application/pdf')
    graph = emit(stub_resource('DataFile', blob: blob))

    dist          = graph.query([RDF::URI(RESOURCE_URI), RDF::URI(DCAT_DIST_P), nil]).first.object
    format_values = graph.query([dist, RDF::URI(DCT_FORMAT), nil]).map { |s| s.object.to_s }
    assert_equal ['application/pdf'], format_values
  end

  test 'does not emit Distribution when content_blob is nil' do
    graph = emit(stub_resource('DataFile', blob: nil))
    dist_links = graph.query([RDF::URI(RESOURCE_URI), RDF::URI(DCAT_DIST_P), nil]).to_a
    assert_empty dist_links
  end

  test 'does not emit Distribution when content_blob is empty' do
    blob  = stub_blob(empty: true)
    graph = emit(stub_resource('DataFile', blob: blob))
    dist_links = graph.query([RDF::URI(RESOURCE_URI), RDF::URI(DCAT_DIST_P), nil]).to_a
    assert_empty dist_links
  end

  test 'does not emit Distribution when resource has no content_blob method' do
    resource = OpenStruct.new(rdf_resource: RDF::URI(RESOURCE_URI))
    klass = klass_stub('Investigation')
    resource.define_singleton_method(:class) { klass }

    graph = emit(resource)
    dist_links = graph.query([RDF::URI(RESOURCE_URI), RDF::URI(DCAT_DIST_P), nil]).to_a
    assert_empty dist_links
  end
end
