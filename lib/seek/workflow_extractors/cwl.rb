require 'rest-client'

module Seek
  module WorkflowExtractors
    class CWL
      CWL_VIEWER_URL = 'http://localhost:8080'
      DIAGRAM_PATH = '/graph/png'

      def initialize(io)
        @io = io
      end

      def diagram
        RestClient.post(CWL_VIEWER_URL + DIAGRAM_PATH, @io.read, content_type: 'text/plain', accept: 'image/png')
      end

      def metadata
        metadata = { warnings: [], errors: [] }
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
