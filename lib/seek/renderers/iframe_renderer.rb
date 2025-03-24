module Seek
  module Renderers
    # Renders "standalone" view in an iframe.
    class IframeRenderer < BlobRenderer
      def render_content
        "<div class=\"blob-display-container\">\n" +
          "<iframe src=\"#{iframe_src}\"></iframe>" +
        "</div>"
      end

      def iframe_src
        blob.content_path(display: display_format)
      end

      def display_format
        raise NotImplementedError
      end

      def render_standalone
        raise NotImplementedError
      end
    end
  end
end
