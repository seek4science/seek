module Seek
  module Renderers
    class RendererFactory
      include Singleton

      @@renderCache = ActiveSupport::Cache::MemoryStore.new(size: 4.megabytes)

      def renderer(blob, url_options: {})
        rendererContent = @@renderCache.read(blob.cache_key)
        if rendererContent.nil?
          rendererContent = detect_renderer(blob).new(blob, url_options: url_options)
          @@renderCache.write(blob.cache_key, rendererContent)
        end
        rendererContent
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
