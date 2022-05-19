module Seek
  module Renderers
    class NotebookRenderer < IframeRenderer
      def can_render?
        blob.is_jupyter_notebook?
      end

      def display_format
        'notebook'
      end

      def render_standalone
        Rails.cache.fetch("notebook-#{blob.cache_key}") do
          f = Tempfile.new('ipynb')
          f.binmode
          f.write(blob.read)
          f.rewind
          require_path = asset_path('assets/require.min.js', skip_pipeline: true)
          mathjax_path = asset_path('assets/mathjax.js', skip_pipeline: true)
          `python3.7 \`which jupyter\` nbconvert --log-level WARN --to html #{f.path} --template lab --stdout --HTMLExporter.mathjax_url=#{mathjax_path} --HTMLExporter.require_js_url=#{require_path}`
        end
      end

      def layout
        false
      end

      def content_security_policy
        "default-src 'self'; img-src * data:; style-src 'unsafe-inline';"
      end
    end
  end
end
