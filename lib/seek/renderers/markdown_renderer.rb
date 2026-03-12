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
        "<div class=\"markdown-body\">#{Seek::Markdown.render(blob.read)}</div>"
      end

      def layout
        'blob'
      end
    end
  end
end
