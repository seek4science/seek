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

  test 'cannot insert with sparql query' do
    id = (DataFile.last&.id || 0) + 1 #get a non existing id
    graph = @repository.get_configuration.public_graph
    count = all_triples_count
    query = "INSERT DATA INTO GRAPH <#{graph}> {
                <http://localhost:3000/data_files/#{id}> <http://jermontology.org/ontology/JERMOntology#description> 'some description' .
            }"

    path = sparql_index_path
    post path, params: { sparql_query: query, format: 'json' }

    #should probably be a different response (not authorized) when fixed
    assert_response :success
    assert_equal count, all_triples_count
  end

  test 'cannot delete with sparql query' do
    create_some_triples
    id = DataFile.last.id
    graph = @repository.get_configuration.public_graph
    count = all_triples_count

    query = "DELETE FROM <#{graph}> {
              <http://localhost:3000/data_files/#{id}> ?p ?o .
             } WHERE {
                <http://localhost:3000/data_files/#{id}> ?p ?o .
             }"

    path = sparql_index_path
    post path, params: { sparql_query: query, format: 'json' }

    #should probably be a different response (not authorized) when fixed
    assert_equal count, all_triples_count
  end

  private

  def create_some_triples
    private_df = FactoryBot.create(:max_data_file, title:'private data file')
    private_df.send_rdf_to_repository

    public_df = FactoryBot.create(:max_data_file, title:'public data file', policy: FactoryBot.create(:public_policy))
    public_df.send_rdf_to_repository
  end

  def all_triples_count
    q = @repository.query.select.where(%i[s p o])
    @repository.select(q).count
  end

end