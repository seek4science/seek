require 'rest-client'

module Seek
  module WorkflowExtractors
    class CWL < Base
      DIAGRAM_PATH = '/graph/%{format}'

      available_diagram_formats(png: 'image/png', svg: 'image/svg+xml', default: :svg)

      def diagram(format = self.class.default_digram_format)
        return nil unless Seek::Config.cwl_viewer_url.present?
        content_type = self.class.diagram_formats[format]
        url = URI.join(Seek::Config.cwl_viewer_url, DIAGRAM_PATH % { format: format }).to_s
        RestClient.post(url, @io.read, content_type: 'text/plain', accept: content_type)
      end

      def metadata
        metadata = super
        cwl_string = @io.read
        cwl = YAML.load(cwl_string)
        if cwl.has_key? 'label'
          metadata[:title] = cwl['label']
        else
          metadata[:warnings] << 'Unable to determine title of workflow'
        end
        if cwl.has_key? 'doc'
          metadata[:description] = cwl['doc']
        end

        metadata
      end
    end
  end
end
