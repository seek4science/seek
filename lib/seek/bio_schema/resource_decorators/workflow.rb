module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Workflow
      class Workflow < CreativeWork

        def schema_type
          "Workflow"
        end

      end
    end
  end
end
