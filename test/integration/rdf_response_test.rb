require 'test_helper'

class RdfResponseTest < ActionDispatch::IntegrationTest

  test 'rdf mime types' do
    project = FactoryBot.create :project
    graph = RDF::Graph.new do |graph|
      RDF::Reader.for(:ttl).new(project.to_rdf) {|reader| graph << reader}
    end
    statement_count = graph.statements.count

    get project_url(project),headers: {'Accept'=>'application/rdf'}
    assert_equal 'text/turtle', @response.media_type
    graph = RDF::Graph.new do |graph|
      RDF::Reader.for(:ttl).new(@response.body) {|reader| graph << reader}
    end
    assert_equal statement_count, graph.statements.count

    get project_url(project),headers: {'Accept'=>'application/x-turtle'}
    assert_equal 'text/turtle', @response.media_type
    graph = RDF::Graph.new do |graph|
      RDF::Reader.for(:ttl).new(@response.body) {|reader| graph << reader}
    end
    assert_equal statement_count, graph.statements.count

    get project_url(project),headers: {'Accept'=>'text/turtle'}
    assert_equal 'text/turtle', @response.media_type
    graph = RDF::Graph.new do |graph|
      RDF::Reader.for(:ttl).new(@response.body) {|reader| graph << reader}
    end
    assert_equal statement_count, graph.statements.count

  end
end
