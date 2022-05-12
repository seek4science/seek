module Seek
  module Renderers
    class RendererFactory
      include Singleton

      def renderer(blob)
        detect_renderer(blob)
      end

      private

      def detect_renderer(blob)
        type = renderer_instances.detect do |type|
          type.new(blob).can_render?
        end
        type.new(blob) if type
      end

      # Ordered list of Renderer classes. More generic renderers appear last.
      def renderer_instances
        [SlideshareRenderer, YoutubeRenderer, MarkdownRenderer, NotebookRenderer, PdfRenderer, ImageRenderer, TextRenderer, BlankRenderer]
      end
    end
  end
end
