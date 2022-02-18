module CommonMarker
  class SeekHtmlRenderer < CommonMarker::HtmlRenderer
    # Add `rel="nofollow"` to links.
    def link(node)
      out('<a rel="nofollow" href="', node.url.nil? ? '' : escape_href(node.url), '"')
      out(' title="', escape_html(node.title), '"') if node.title && !node.title.empty?
      out('>', :children, '</a>')
    end
  end
end
