module Seek
  module Renderers
    class ImageRenderer < BlobRenderer
      def can_render?
        blob.is_image?
      end

      def render_content
        link_to(image_tag(content_path, class: 'git-image-preview'), content_path, title: 'Click for full')
      end
    end
  end
end
