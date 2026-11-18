require 'test_helper'

class SparqlHelperTest < ActionView::TestCase
  test 'result columns are the query variables, otherwise those of all the rows' do
    results = [{ a: RDF::Literal('1') }, { b: RDF::Literal('2'), a: RDF::Literal('3') }]
    assert_equal %i[a b], sparql_result_columns(results)

    @result_columns = %i[b a]
    assert_equal %i[b a], sparql_result_columns(results)
  end
end
