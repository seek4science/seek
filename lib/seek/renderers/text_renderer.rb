module Seek
  module Renderers
    class TextRenderer < BlobRenderer
      def can_render?
        blob.is_text?
      end

      def is_remote?
        false
      end

      def render_content
        "<pre>#{blob.read}</pre>"
      end

      def render_standalone
        blob.read
      end

      def format
        :plain
      end
    end
  end
end
