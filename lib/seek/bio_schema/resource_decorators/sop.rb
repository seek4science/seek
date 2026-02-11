module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Sop
      class Sop < CreativeWork
        LAB_PROTOCOL_TYPE = 'https://bioschemas.org/types/LabProtocol/0.5-DRAFT'.freeze

        associated_items computational_tool: :workflows
        schema_mappings computational_tool: :computationalTool

        def context
          super.merge(
            LabProtocol: LAB_PROTOCOL_TYPE,
            computationalTool: "#{LAB_PROTOCOL_TYPE}#computationalTool"
          )
        end

        def mini_context
          super.merge(LabProtocol: LAB_PROTOCOL_TYPE)
        end

        def schema_type
          'LabProtocol'
        end

      end
    end
  end
end