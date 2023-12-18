module Seek
  module Renderers
    class SvgRenderer < ImageRenderer
      def can_render?
        blob.is_svg?
      end

      def render_content
        path = blob.content_path
        content_tag(:embed, '', type: 'image/svg+xml', src: path, class: 'svg-pan-zoom')
      end
    end
  end
end
