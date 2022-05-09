module Seek
  module Renderers
    class BlobRenderer
      include ActionView::Helpers

      attr_reader :blob

      def initialize(git_blob_or_blob)
        @blob = git_blob_or_blob
      end

      def render
        render_content
      rescue Exception => exception
        handle_render_exception(blob, exception)
        ''
      end

      def can_render?
        fail 'needs to be implemented'
      end

      private

      def handle_render_exception(blob, exception)
        Seek::Errors::ExceptionForwarder.send_notification(exception,
                                                           data:{ message: 'rendering error',
                                                                  renderer: self,
                                                                  item: blob.inspect })
      end
    end
  end
end
