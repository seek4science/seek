module Seek
  module Renderers
    class TextRenderer < BlobRenderer
      def can_render?
        blob.is_text?
      end

      def render_content
        content = blob.read
        if content.empty?
          '<span class="subtle">No content to display</span>'
        else
          "<pre>#{h(content)}</pre>"
        end

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
