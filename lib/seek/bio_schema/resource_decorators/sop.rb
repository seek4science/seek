module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Sop
      class Sop < CreativeWork
        LAB_PROTOCOL_TYPE = 'https://bioschemas.org/types/LabProtocol/0.5-DRAFT'.freeze
        COMPUTATIONAL_TOOL_PROPERTY = 'https://bioschemas.org/terms/computationalTool'.freeze

        associated_items computational_tool: :workflows
        schema_mappings computational_tool: :computationalTool

        def context
          super.merge(
            LabProtocol: LAB_PROTOCOL_TYPE,
            computationalTool: COMPUTATIONAL_TOOL_PROPERTY
          )
        end

        def schema_type
          'LabProtocol'
        end

      end
    end
  end
end