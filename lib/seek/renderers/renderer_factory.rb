module Seek
  module Renderers
    class RendererFactory
      include Singleton

      def renderer(blob, url_options: {})
        detect_renderer(blob).new(blob, url_options: url_options)
      end

      private

      def detect_renderer(blob)
        renderer_instances.detect do |type|
          type.new(blob).can_render?
        end
      end

      # Ordered list of Renderer classes. More generic renderers appear last.
      def renderer_instances
        [SlideshareRenderer, YoutubeRenderer, MarkdownRenderer, NotebookRenderer, TextRenderer, PdfRenderer, ImageRenderer, BlankRenderer]
      end
    end
  end
end
