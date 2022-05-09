module Seek
  module Renderers
    class TextRenderer < BlobRenderer
      def can_render?
        blob.is_text?
      end

      def render_content
        "<pre>#{read}</pre>"
      end
    end
  end
end
