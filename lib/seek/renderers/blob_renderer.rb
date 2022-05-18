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

      # Render an HTML string that can be embedded in an existing view
      def render_content
        fail 'needs to be implemented'
      end

      def can_render?
        fail 'needs to be implemented'
      end

      # Render an entire HTML page
      def render_standalone
        render_template('content_blobs/view_content_frame',
                    { renderer: self },
                    layout: layout)
      end

      def layout
        'blob'
      end

      # Content-Security-Policy for the rendered view
      def content_security_policy
        ApplicationController::USER_CONTENT_CSP
      end

      private

      def handle_render_exception(blob, exception)
        Seek::Errors::ExceptionForwarder.send_notification(exception,
                                                           data:{ message: 'rendering error',
                                                                  renderer: self,
                                                                  item: blob.inspect })
      end

      def render_template(template_path, variables = {}, layout: 'application')
        ApplicationController.renderer.render(
          template: template_path,
          assigns: variables,
          layout: layout
        )
      end
    end
  end
end
