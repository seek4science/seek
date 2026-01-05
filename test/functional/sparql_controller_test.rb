require 'test_helper'
require 'minitest/mock'

class SparqlControllerTest < ActionController::TestCase

  # these tests cover the case where the sparql endpoint isn't configured. For cases where the triple store is available
  # please see the test/integration/sparql_controller_test

  test 'index' do
    Seek::Rdf::RdfRepository.instance.stub(:configured?, ->(){ false }) do
      refute Seek::Rdf::VirtuosoRepository.instance.configured?
      get :index
      assert_redirected_to :root
      assert_equal 'SPARQL endpoint is not configured.', flash[:error]
    end
  end

  test 'post sparql to index' do
    Seek::Rdf::RdfRepository.instance.stub(:configured?, ->(){ false }) do
      refute Seek::Rdf::VirtuosoRepository.instance.configured?
      query = 'ask where {?s ?p ?o}'
      post :index, params: { sparql_query: query, format: 'json' }
      assert_redirected_to :root
      assert_equal 'SPARQL endpoint is not configured.', flash[:error]
    end
  end

end