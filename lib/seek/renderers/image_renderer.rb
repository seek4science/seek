module Seek
  module Renderers
    class ImageRenderer < BlobRenderer
      def can_render?
        blob.is_image?
      end

      def render_content
        path = blob.content_path
        link_to(image_tag(path, class: 'git-image-preview'), path, title: 'Click for full')
      end
    end
  end
end
