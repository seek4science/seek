module Seek
  module Renderers
    class MarkdownRenderer < IframeRenderer
      def can_render?
        blob.is_markdown?
      end

      def display_format
        'markdown'
      end

      def render_standalone
        doc = CommonMarker.render_doc(blob.read, :UNSAFE, [:tagfilter, :table, :strikethrough, :autolink])
        renderer = CommonMarker::SeekHtmlRenderer.new(options: [:UNSAFE, :GITHUB_PRE_LANG], extensions: [:tagfilter, :table, :strikethrough, :autolink])
        "<div class=\"markdown-body\">#{renderer.render(doc)}</div>"
      end

      def layout
        'blob'
      end
    end
  end
end
