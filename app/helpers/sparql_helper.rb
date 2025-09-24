module SparqlHelper

  def sparql_results_panel_title
    "<i class='glyphicon glyphicon-ok-circle'></i>&nbspQuery Results (#{@results.length} results)"
  end

  def sparql_examples_panel_title
    '<span class="glyphicon glyphicon-list-alt"></span>&nbsp;Example Queries'
  end

end