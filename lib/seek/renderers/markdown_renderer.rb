module Seek
  module Renderers
    class MarkdownRenderer < BlobRenderer
      def can_render?
        blob.is_markdown?
      end

      def render_content
        "<div class=\"blob-display-container\">\n" +
          "<iframe src=\"#{blob.content_path(display: 'markdown')}\"></iframe>" +
        "</div>"
      end

      def render_iframe_contents
        doc = CommonMarker.render_doc(blob.read, :UNSAFE, [:tagfilter, :table, :strikethrough, :autolink])
        renderer = CommonMarker::SeekHtmlRenderer.new(options: [:UNSAFE, :GITHUB_PRE_LANG], extensions: [:tagfilter, :table, :strikethrough, :autolink])
        "<div class=\"markdown-body\">#{renderer.render(doc)}</div>"
      end

      def iframe_layout
        'blob'
      end

      def iframe_csp
        "default-src 'self'"
      end
    end
  end
end
