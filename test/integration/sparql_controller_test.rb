require 'test_helper'

class SparqlControllerTest < ActionDispatch::IntegrationTest

  def setup
    @repository = Seek::Rdf::RdfRepository.instance
    @private_graph = RDF::URI.new @repository.get_configuration.private_graph
    @public_graph = RDF::URI.new @repository.get_configuration.public_graph
    skip('these tests need a configured triple store setup') unless @repository.configured?
  end
  def teardown
    return unless @repository.configured?
    q = @repository.query.delete(%i[s p o]).graph(@private_graph).where(%i[s p o])
    @repository.delete(q)

    q = @repository.query.delete(%i[s p o]).graph(@public_graph).where(%i[s p o])
    @repository.delete(q)
  end


  test 'get index' do
    path = sparql_index_path
    get path
    assert_response :success
    assert_select '#content .container-fluid' do
      assert_select 'div#error_flash', text: /SPARQL endpoint is not configured/, count: 0
      assert_select 'div.sparql-interface' do
        assert_select 'form[action=?][method=?]', sparql_index_path, 'post' do
          assert_select 'textarea.sparql-textarea'
        end
        assert_select 'div.sparql-examples div.panel'
      end
    end
  end

  test 'post sparql query and json response' do
    path = sparql_index_path
    create_some_triples
    query = 'SELECT ?datafile ?title ?graph
      WHERE {
        GRAPH ?graph {
          ?datafile a <http://jermontology.org/ontology/JERMOntology#Data> .
          ?datafile <http://purl.org/dc/terms/title> "public data file" .
          ?datafile <http://purl.org/dc/terms/title> ?title .
        }
      }'

    post path, params: { sparql_query: query, format: 'json' }
    assert_response :success
    json = JSON.parse(@response.body)

    # should be 1 when it's fixed to only check the public graph
    assert_equal 2, json.length

    query = 'SELECT ?datafile ?title ?graph
      WHERE {
        GRAPH ?graph {
          ?datafile a <http://jermontology.org/ontology/JERMOntology#Data> .
          ?datafile <http://purl.org/dc/terms/title> "private data file" .
          ?datafile <http://purl.org/dc/terms/title> ?title .
        }
      }'

    post path, params: { sparql_query: query, format: 'json' }
    assert_response :success
    json = JSON.parse(@response.body)

    # should be 1 when it's fixed to only check the public graph
    assert_equal 1, json.length
  end

  private

  def create_some_triples
    private_df = FactoryBot.create(:max_data_file, title:'private data file')
    private_df.send_rdf_to_repository

    private_df = FactoryBot.create(:max_data_file, title:'public data file', policy: FactoryBot.create(:public_policy))
    private_df.send_rdf_to_repository

  end

end