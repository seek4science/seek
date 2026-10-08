module Seek
  module Renderers
    class TextRenderer < BlobRenderer
      # the maximum amount of content that is rendered, anything beyond this is truncated
      MAX_RENDERABLE_SIZE = 1.megabyte

      def can_render?
        blob.is_text?
      end

      def render_content
        content, truncated = text_content
        if content.empty?
          '<span class="subtle">No content to display</span>'
        else
          html = "<pre>#{h(content)}</pre>"
          html << "<p class=\"subtle\">#{h(truncation_message)}</p>" if truncated
          html
        end
      end

      def render_standalone
        content, truncated = text_content
        truncated ? "#{content}\n\n#{truncation_message}\n" : content
      end

      def format
        :plain
      end

      private

      # the content of the blob, limited to MAX_RENDERABLE_SIZE, along with whether it was truncated.
      # Bytes that aren't valid UTF-8 are replaced, since they would otherwise break string handling
      # and the encoding of the response
      def text_content
        blob.rewind
        content = blob.read(MAX_RENDERABLE_SIZE + 1).to_s.dup.force_encoding(Encoding::UTF_8)
        truncated = content.bytesize > MAX_RENDERABLE_SIZE
        content = content.encode('UTF-8', invalid: :replace, undef: :replace)
        if content.bytesize > MAX_RENDERABLE_SIZE
          # replacing invalid bytes can grow the content, and the limit may fall within a character
          content = content.byteslice(0, MAX_RENDERABLE_SIZE).scrub('')
          truncated = true
        end
        [content, truncated]
      end

      def truncation_message
        I18n.t('renderers.truncated_content', size: number_to_human_size(MAX_RENDERABLE_SIZE))
      end
    end
  end
end
