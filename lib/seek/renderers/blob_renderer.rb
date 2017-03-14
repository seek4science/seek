module Seek
  module Renderers
    class BlobRenderer
      attr_reader :content_blob

      def initialize(content_blob)
        @content_blob = content_blob
      end

      def render
        render_content
      rescue Exception => exception
        handle_render_exception(content_blob, exception)
        ''
      end

      def can_render?
        fail 'needs to be implemented'
      end

      private

      def handle_render_exception(content_blob, exception)
        if Seek::Config.exception_notification_enabled
          data = { message: 'rendering error', renderer: self, item: content_blob.inspect }
          ExceptionNotifier.notify_exception(exception, data: data)
        end
      end
    end
  end
end
