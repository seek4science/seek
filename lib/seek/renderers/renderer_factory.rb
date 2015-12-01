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
        if type
          type.new(content_blob)
        end
      end

      def renderer_instances
        #Seek::Renderers::Renderer.descendants
        [Seek::Renderers::SlideshareRenderer]
      end

    end
  end
end