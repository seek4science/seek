module Seek
  module WorkflowExtractors
    class Galaxy < Base
      def metadata
        metadata = super
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
