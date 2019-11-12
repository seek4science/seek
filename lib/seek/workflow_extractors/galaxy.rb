module Seek
  module WorkflowExtractors
    class Galaxy
      def initialize(io)
        @io = io
      end

      def diagram
        nil
      end

      def metadata
        metadata = { warnings: [], errors: [] }
        galaxy_string = @io.read
        galaxy = JSON.parse(galaxy_string)
        if galaxy.has_key? "name"
          metadata[:title] = galaxy["name"]
        else
          metadata[:warnings] = 'Unable to determine title of workflow'
        end

        metadata
      end
    end
  end
end
