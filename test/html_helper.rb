module HtmlHelper

  def select_node(selector)
    node = HTML::Selector.new(selector).select(html_document.root)[0]
    node.to_s
  end

  def select_node_contents(selector)
    node = HTML::Selector.new(selector).select(html_document.root)[0]
    node.children.map { |c| c.to_s }.join
  end

end
