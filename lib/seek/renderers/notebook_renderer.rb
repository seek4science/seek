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
          generate_notebook_html
        end
      end

      def layout
        false
      end

      def content_security_policy
        "default-src 'self'; img-src * data:; style-src 'unsafe-inline';"
      end

      private

      def generate_notebook_html
        f = Tempfile.new('ipynb')
        f.binmode
        f.write(blob.read)
        f.rewind
        require_path = asset_path('assets/require.min.js', skip_pipeline: true)
        mathjax_path = asset_path('assets/mathjax.js', skip_pipeline: true)
        out = ''
        err = ''
        status = Open4.popen4(Seek::Util.python_exec("-m nbconvert --log-level WARN --to html #{f.path} --template lab --stdout --HTMLExporter.mathjax_url=#{mathjax_path} --HTMLExporter.require_js_url=#{require_path}")) do |_pid, _stdin, stdout, stderr|
          while (line = stdout.gets) != nil
            out << line
          end
          err = stderr.read.strip
          stdout.close
          stderr.close
        end

        if status.success?
          out
        else
          raise "Error rendering notebook: #{err}"
        end
      end
    end
  end
end
