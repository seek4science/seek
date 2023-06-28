module Seek
  module Renderers
    class CitationRenderer < BlobRenderer
      def can_render?
        blob.is_cff?
      end

      def render_content
        render_partial('assets/citation_from_cff', blob: blob, style: style)
      end

      private

      def style
        params[:style] || Seek::Citations::DEFAULT
      end
    end
  end
end
