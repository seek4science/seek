module HtmlHelper
  def select_node(selector)
    node = html_document.css(selector).first
    node.to_s
  end

  def select_node_contents(selector)
    node = html_document.css(selector).first
    node.children.map(&:to_s).join
  end
end
