module Seek
  module Renderers
    class RendererFactory
      include Singleton

      def renderer(content_blob)
        detect_renderer(content_blob) || Seek::Renderers::BlankRenderer.new
      end

      private

      def detect_renderer(content_blob)
        type = renderer_instances.detect do |type|
          type.new(content_blob).can_render?
        end
        type.new(content_blob) if type
      end

      def renderer_instances
        # Seek::Renderers::Renderer.descendants
        [Seek::Renderers::SlideshareRenderer, Seek::Renderers::YoutubeRenderer]
      end
    end
  end
end
