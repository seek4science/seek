module Seek
  module Renderers
    class MarkdownRenderer < BlobRenderer
      def can_render?
        path.downcase.end_with?('.md')
      end

      def render_content
        doc = CommonMarker.render_doc(read, :UNSAFE, [:tagfilter, :table, :strikethrough, :autolink])
        renderer = CommonMarker::SeekHtmlRenderer.new(options: [:UNSAFE, :GITHUB_PRE_LANG], extensions: [:tagfilter, :table, :strikethrough, :autolink])
        renderer.render(doc)
      end
    end
  end
end
