module Seek
  module Renderers
    class RendererFactory
      include Singleton

      def renderer(blob, url_options: {}, params: {})
        renderer_class = cache.fetch(blob.cache_key) { detect_renderer(blob).name }.constantize

        renderer_class.new(blob, url_options: url_options, params: params)
      end

      private

      def cache
        @cache ||= ActiveSupport::Cache::MemoryStore.new(size: 1.megabytes)
      end

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
