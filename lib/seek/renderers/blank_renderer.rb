module Seek
  module Renderers
    # Provides a blank rendition, for something that isn't recognised as being renderable
    class BlankRenderer < BlobRenderer
      def can_render?
        true
      end

      def render
        ''
      end
    end
  end
end
