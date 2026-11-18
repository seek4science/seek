module SparqlHelper

  def sparql_results_panel_title
    "<i class=\"glyphicon glyphicon-ok-circle\"></i>&nbsp;Query Results (#{@results.length} results)"
  end

  def sparql_examples_panel_title
    '<span class="glyphicon glyphicon-list-alt"></span>&nbsp;Example Queries'
  end

  # The columns of the SPARQL results table: the variables of a SELECT query, otherwise those of all the rows, as a
  # row doesn't hold the variables that weren't bound for it.
  def sparql_result_columns(results)
    @result_columns.presence || results.flat_map(&:keys).uniq
  end

end