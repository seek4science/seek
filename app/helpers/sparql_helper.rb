module SparqlHelper

  def sparql_results_panel_title
    "<i class=\"glyphicon glyphicon-ok-circle\"></i>&nbsp;Query Results (#{@results.length} results)"
  end

  # Displays a value of the SPARQL results, distinguishing the kind of RDF term. An IRI (a node in the graph) is shown
  # within <>, as in SPARQL and Turtle, a blank node with its _: label, and a literal as its plain value. Any that
  # are http(s) URLs are linked.
  def sparql_result_value(value)
    case value
    when RDF::URI
      content_tag(:span, safe_join(['<', sparql_result_link(value.to_s), '>']), class: 'sparql-iri',
                                                                                 title: 'IRI (node)')
    when RDF::Node
      content_tag(:span, value.to_s, class: 'sparql-bnode', title: 'Blank node')
    else
      content_tag(:span, sparql_result_link(value.to_s), class: 'sparql-literal', title: sparql_literal_title(value))
    end
  end

  private

  def sparql_result_link(text)
    if text.match?(%r{\Ahttps?://})
      link_to(text, text, class: 'external-link', data: { tooltip: text })
    else
      text
    end
  end

  def sparql_literal_title(value)
    return 'Literal' unless value.is_a?(RDF::Literal)

    if value.language?
      "Literal (@#{value.language})"
    elsif value.datatype? && value.datatype != RDF::XSD.string
      "Literal (#{value.datatype.pname})"
    else
      'Literal'
    end
  end
end
