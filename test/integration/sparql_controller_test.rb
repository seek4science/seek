require 'test_helper'
require 'minitest/mock'

class SparqlControllerTest < ActionDispatch::IntegrationTest

  def setup
    @repository = Seek::Rdf::RdfRepository.instance
    skip('these tests need a configured triple store setup') unless @repository.configured?
    @private_graph = RDF::URI.new @repository.get_configuration.private_graph
    @public_graph = RDF::URI.new @repository.get_configuration.public_graph

    VCR.configure do |c|
      c.allow_http_connections_when_no_cassette = true
    end

  end
  def teardown
    return unless @repository.configured?

    q = @repository.query.delete(%i[s p o]).graph(@private_graph).where(%i[s p o])
    @repository.delete(q)

    q = @repository.query.delete(%i[s p o]).graph(@public_graph).where(%i[s p o])
    @repository.delete(q)
    VCR.configure do |c|
      c.allow_http_connections_when_no_cassette = false
    end
  end


  test 'get index' do
    path = sparql_index_path
    get path
    assert_response :success
    assert_select '#content .container-fluid' do
      assert_select 'div#error_flash', count: 0
      assert_select 'div.sparql-interface' do
        assert_select 'form[action=?][method=?]', query_sparql_index_path, 'post' do
          assert_select 'textarea.sparql-textarea', text: ''
          assert_select 'select#format option[selected=selected][value=?]', 'html'
        end
        assert_select 'div.sparql-examples div.panel'
      end
    end
  end

  test 'params populate the query and format' do
    query = 'This is a sparql query'
    format = 'json'
    get sparql_index_path, params: { sparql_query: query, output_format: format }
    assert_response :success
    assert_select 'div#error_flash', count: 0
    assert_select 'div.sparql-interface' do
      assert_select 'form[action=?][method=?]', query_sparql_index_path, 'post' do
        assert_select 'textarea.sparql-textarea', text: query
        assert_select 'select#format option[selected=selected][value=?]', format
      end
    end
  end

  test 'post sparql query and json response' do
    path = query_sparql_index_path
    create_some_triples
    query = 'SELECT ?datafile ?title
      WHERE {
        ?datafile a <http://jermontology.org/ontology/JERMOntology#Data> .
        ?datafile <http://purl.org/dc/terms/title> "public data file" .
        ?datafile <http://purl.org/dc/terms/title> ?title .
      }'

    post path, params: { sparql_query: query, format: 'json' }
    assert_response :success
    json = JSON.parse(@response.body)

    assert_equal 1, json['results'].length

    query = 'SELECT ?datafile ?title
      WHERE {
        ?datafile a <http://jermontology.org/ontology/JERMOntology#Data> .
        ?datafile <http://purl.org/dc/terms/title> "private data file" .
        ?datafile <http://purl.org/dc/terms/title> ?title .
      }'

    post path, params: { sparql_query: query, format: 'json' }
    assert_response :success
    json = JSON.parse(@response.body)

    assert_empty json['results']
    assert_nil json['error']
  end

  test 'post sparql query and html response' do
    path = query_sparql_index_path
    create_some_triples
    query = 'SELECT ?datafile ?title
      WHERE {
        ?datafile a <http://jermontology.org/ontology/JERMOntology#Data> .
        ?datafile <http://purl.org/dc/terms/title> "public data file" .
        ?datafile <http://purl.org/dc/terms/title> ?title .
      }'

    post path, params: { sparql_query: query }
    assert_response :success
    assert_select 'div#query-error', count: 0

    assert_select 'div#sparql-results table' do
      assert_select 'tbody tr', count: 1
      assert_select 'thead th', count: 2
      assert_select 'td', text: 'public data file', count: 1
    end
  end

  test 'demonstrate that the default public graph can be worked around' do
    path = query_sparql_index_path
    create_some_triples
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

    assert_equal 1, json['results'].length
    assert_equal 'private data file', json['results'].first['title']
    assert_equal 'seek-testing:private', json['results'].first['graph']
    assert_nil json['error']
  end

  test 'post invalid sparql' do
    path = query_sparql_index_path
    create_some_triples

    query = 'SEECT ?datafile ?invalid ?graph
      WHERE {
        GRAPH ?graph {
          ?datafile a <http://jermontology.org/ontology/JERMOntology#Data> .
          ?datafile <http://purl.org/dc/terms/title> "public data file" .
          ?datafile <http://purl.org/dc/terms/title> ?title .
        }
      }'

    post path, params: { sparql_query: query }
    assert_response :unprocessable_entity
    assert_nil flash[:error] # a query error is shown in the results box

    assert_select 'div#query-error.alert-danger' do
      assert_select 'h4', text:/Query Error/
      assert_select 'pre', text:/SPARQL compiler, line 3: syntax error at 'SEECT'/
    end

    post path, params: { sparql_query: query, format: 'json' }
    assert_response :unprocessable_entity
    json = JSON.parse(@response.body)

    assert_match /SPARQL compiler, line 3: syntax error at 'SEECT'/, json['error']

  end

  test 'handle single result e.g ask' do
      path = query_sparql_index_path
      create_some_triples
      query = 'ask where {?s ?p ?o}'

      post path, params: { sparql_query: query, format: 'json' }
      assert_response :success
      json = JSON.parse(@response.body)
      expected = {'result' => 'true'}
      assert_equal expected, json['results'].first

      post path, params: { sparql_query: query }
      assert_response :success
      assert_select 'div#sparql-results table' do
        assert_select 'tbody tr', count: 1
        assert_select 'tbody td', text: 'true', count: 1
        assert_select 'thead th', count: 1
        assert_select 'thead th', text:'Result', count: 1
      end

  end

  test 'respond with json when using content negotiation' do
    path = query_sparql_index_path
    create_some_triples
    query = 'ask where {?s ?p ?o}'

    post path, params: { sparql_query: query }, headers: { 'Accept' => 'application/json' }
    assert_response :success
    json = JSON.parse(@response.body)
    expected = {'result' => 'true'}
    assert_equal expected, json['results'].first
  end

  test 'cannot insert with sparql query' do
    id = (DataFile.last&.id || 0) + 1 #get a non existing id
    graph = @repository.get_configuration.public_graph
    count = all_triples_count
    query = "INSERT DATA INTO GRAPH <#{graph}> {
                <http://localhost:3000/data_files/#{id}> <http://jermontology.org/ontology/JERMOntology#description> 'some description' .
            }"

    path = query_sparql_index_path
    post path, params: { sparql_query: query, format: 'json' }

    #should probably be a different response (not authorized) when fixed
    assert_response :unprocessable_entity
    assert_equal count, all_triples_count
    json = JSON.parse(@response.body)
    assert_match /SECURITY: No permission to execute procedure/, json['error']
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

    path = query_sparql_index_path
    post path, params: { sparql_query: query, format: 'json' }

    assert_response :unprocessable_entity
    assert_equal count, all_triples_count
    json = JSON.parse(@response.body)
    assert_match /SECURITY: No permission to execute procedure/, json['error']
  end

  test 'repository not available' do
    path = query_sparql_index_path
    Seek::Rdf::RdfRepository.instance.stub(:available?, ->(){ false }) do
      get sparql_index_path
      assert_response :success
      assert_equal 'SPARQL endpoint is configured, but not currently available.', flash[:error]
      assert_select 'div#error_flash', text:/SPARQL endpoint is configured, but not currently available/

      query = 'ask where {?s ?p ?o}'
      post path, params: { sparql_query: query }
      assert_response :unprocessable_entity
      assert_equal 'SPARQL endpoint is configured, but not currently available.', flash[:error]
      assert_select 'div#error_flash', text:/SPARQL endpoint is configured, but not currently available/
      assert_empty assigns(:results)

      query = 'ask where {?s ?p ?o}'
      post path, params: { sparql_query: query, format: 'json' }
      assert_response :unprocessable_entity
      assert_empty assigns(:results)
      json = JSON.parse(@response.body)
      assert_match /SPARQL endpoint is configured, but not currently available/, json['error']
    end
  end

  private

  def create_some_triples
    private_df = FactoryBot.create(:max_data_file, title: 'private data file')
    private_df.send_rdf_to_repository

    public_df = FactoryBot.create(:max_data_file, title: 'public data file', policy: FactoryBot.create(:public_policy))
    public_df.send_rdf_to_repository
  end

  def all_triples_count
    q = @repository.query.select.where(%i[s p o])
    @repository.select(q).count
  end

end