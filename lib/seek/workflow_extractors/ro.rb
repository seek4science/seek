module Seek
  module WorkflowExtractors
    class RO
      def initialize(io)
        @io = io
      end

      def diagram
        nil
      end

      def metadata
        metadata = { warnings: [], errors: [] }
        ro_string = @io.read
        ro = JSON.parse(ro_string)
        if ro.has_key? "name"
          metadata[:title] = ro["name"]
        else
          metadata[:warnings] << 'Unable to determine title of workflow'
        end
        if ro.has_key? "description"
          metadata[:description] = ro["description"]
        end

        metadata
      end
    end
  end
end
