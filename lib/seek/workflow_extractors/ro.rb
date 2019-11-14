module Seek
  module WorkflowExtractors
    class RO < Base
      def metadata
        metadata = super
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
