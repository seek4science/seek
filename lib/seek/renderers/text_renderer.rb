module Seek
  module Renderers
    class TextRenderer < BlobRenderer
      def can_render?
        blob.is_text?
      end

      def render_content
        content = text_content
        if content.empty?
          '<span class="subtle">No content to display</span>'
        else
          "<pre>#{h(content)}</pre>"
        end

      end

      def render_standalone
        text_content
      end

      def format
        :plain
      end

      private

      # the content of the blob, with any bytes that aren't valid UTF-8 replaced, since they would
      # otherwise break string handling and the encoding of the response
      def text_content
        blob.read.to_s.encode('UTF-8', invalid: :replace, undef: :replace)
      end
    end
  end
end
