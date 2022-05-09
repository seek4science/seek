module Seek
  module Renderers
    class NotebookRenderer < BlobRenderer
      def can_render?
        path.downcase.end_with?('.ipynb')
      end

      def render_content
        "<div class=\"notebook-container\">\n" +
          "<iframe src=\"#{content_path(display: 'notebook')}\"></iframe>" +
        "</div"
      end
    end
  end
end
