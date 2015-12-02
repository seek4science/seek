module Seek
  module Renderers
    class BlobRenderer
      attr_reader :content_blob

      def initialize(content_blob)
        @content_blob = content_blob
      end

      def can_render?
        fail 'needs to be implemented'
      end
    end
  end
end
