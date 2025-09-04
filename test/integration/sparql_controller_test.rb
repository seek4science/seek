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

  test 'post query format json' do
    path = sparql_index_path
    create_some_triples
    query = 'SELECT (COUNT(*) AS ?count) WHERE {?subject ?predicate ?object}'
    post path, params: { sparql_query: query, format: 'json' }
    assert_response :success
    json = JSON.parse(@response.body)
    count = json[0]['count'].to_i

    # count may vary, but a rough approximation to check it works. Expect count to be lower when querying the public graph
    assert count.between?(3000, 8000)
  end

  private

  def create_some_triples
    df = FactoryBot.create(:max_data_file)
    df.send_rdf_to_repository
  end

end