module Seek
  module Renderers
    class NotebookRenderer < BlobRenderer
      def can_render?
        blob.is_jupyter_notebook?
      end

      def render_content
        "<div class=\"blob-display-container\">\n" +
          "<iframe src=\"#{blob.content_path(display: 'notebook')}\">Loading...</iframe>" +
        "</div>"
      end

      def render_iframe_contents
        Rails.cache.fetch("notebook-#{blob.cache_key}") do
          f = Tempfile.new('ipynb')
          f.binmode
          f.write(blob.read)
          f.rewind
          require_path = asset_path('assets/require.min.js', skip_pipeline: true)
          mathjax_path = asset_path('assets/mathjax.js', skip_pipeline: true)
          `jupyter nbconvert --to html #{f.path} --template lab --stdout --HTMLExporter.mathjax_url=#{mathjax_path} --HTMLExporter.require_js_url=#{require_path}`
        end
      end

      def iframe_layout
        false
      end

      def iframe_csp
        "default-src 'self'; img-src * data:; style-src 'unsafe-inline';"
      end
    end
  end
end
