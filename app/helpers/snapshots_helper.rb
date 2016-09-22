require 'citeproc'
require 'csl/styles'

module SnapshotsHelper

  def render_citation(snapshot, style = 'apa')
    cp = CiteProc::Processor.new(style: style, format: 'html')
    cp.register(snapshot.to_csl.merge(id: :snapshot))
    cp.render(:bibliography, id: :snapshot).last.html_safe
  rescue JSON::ParserError, RestClient::Exception
    'An error occurred whilst fetching the citation'
  end

  def citation_style_options
    options_for_select(CSL::Style.list.sort)
  end

end
