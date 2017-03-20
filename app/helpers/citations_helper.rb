require 'citeproc'
require 'csl/styles'

module CitationsHelper
  def render_citation(doi, style = 'apa')
    Seek::CitationGenerator.new(doi).generate(style)
  rescue JSON::ParserError, RestClient::Exception
    'An error occurred whilst fetching the citation'
  end

  def citation_style_options
    options_for_select(CSL::Style.list.sort)
  end
end
