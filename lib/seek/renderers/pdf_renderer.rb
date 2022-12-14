module Seek
  module Renderers
    class PdfRenderer < IframeRenderer
      def can_render?
        blob.is_pdf? ||
          blob.is_pdf_viewable? && Seek::Config.pdf_conversion_enabled
      end

      def render_standalone
        render_template('content_blobs/view_pdf_content',
                        { content_blob: blob,
                          pdf_url: blob.content_path(@url_options.reverse_merge(format: 'pdf', intent: :inline_view)) },
                        layout: layout)
      end

      def display_format
        'pdf'
      end

      def layout
        false
      end

      def content_security_policy
        nil
      end
    end
  end
end
