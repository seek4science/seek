module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Sop
      class Sop < CreativeWork

        associated_items computational_tool: :workflows
        schema_mappings computational_tool: :computationalTool

        def schema_type
          'LabProtocol'
        end

      end
    end
  end
end