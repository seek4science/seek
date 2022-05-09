module Seek
  module Renderers
    class MarkdownRenderer < BlobRenderer
      def can_render?
        blob.is_markdown?
      end

      def render_content
        doc = CommonMarker.render_doc(blob.read, :UNSAFE, [:tagfilter, :table, :strikethrough, :autolink])
        renderer = CommonMarker::SeekHtmlRenderer.new(options: [:UNSAFE, :GITHUB_PRE_LANG], extensions: [:tagfilter, :table, :strikethrough, :autolink])
        renderer.render(doc)
      end
    end
  end
end
