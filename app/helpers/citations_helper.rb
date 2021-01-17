require 'citeproc'
require 'csl/styles'

module CitationsHelper
  def render_citation(doi, style)
    Seek::Citations.generate(doi, style)
  rescue JSON::ParserError, RestClient::Exception
    'An error occurred whilst fetching the citation'
  end

  def citation_style_options(selected = nil)
    selected ||= selected_citation_style
    options_for_select(Seek::Citations.style_pairs, selected)
  end

  def selected_citation_style
    session[:citation_style] || Seek::Citations::DEFAULT
  end
end
