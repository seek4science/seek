require 'test_helper'

class SparqlControllerTest < ActionDispatch::IntegrationTest

  def setup
    @repository = Seek::Rdf::RdfRepository.instance
    skip('these tests need a configured triple store setup') unless @repository.configured?
  end

  test 'get index' do
    path = sparql_index_path
    get path
    assert_response :success
    assert_select '#content .container-fluid' do
      assert_select 'div#error_flash', text:/SPARQL endpoint is not configured/, count: 0
      assert_select 'div.sparql-interface' do
        assert_select 'form[action=?][method=?]', sparql_index_path, 'post' do
          assert_select 'textarea.sparql-textarea'
        end
        assert_select 'div.sparql-examples div.panel'
      end
    end
  end

  # test 'post query' do
  #
  # end

end