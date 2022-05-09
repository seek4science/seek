module Seek
  module Renderers
    class RendererFactory
      include Singleton

      def renderer(blob, fallback: Seek::Renderers::BlankRenderer)
        detect_renderer(blob) || fallback.new
      end

      private

      def detect_renderer(blob)
        type = renderer_instances.detect do |type|
          type.new(blob).can_render?
        end
        type.new(blob) if type
      end

      def renderer_instances
        # Seek::Renderers::Renderer.descendants
        [SlideshareRenderer, YoutubeRenderer, MarkdownRenderer, NotebookRenderer, ImageRenderer, TextRenderer]
      end
    end
  end
end
