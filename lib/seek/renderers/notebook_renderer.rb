module Seek
  module Renderers
    class NotebookRenderer < BlobRenderer
      def can_render?
        blob.is_jupyter_notebook?
      end

      def render_content
        "<div class=\"notebook-container\">\n" +
          "<iframe src=\"#{blob.content_path(display: 'notebook')}\"></iframe>" +
        "</div"
      end
    end
  end
end
