module Ga4gh
  module Trs
    module V2
      # Decorator for a Workflow::Version to make it appear as a GA4GH TRS Tool Version.
      class ToolVersion
        include ActiveModel::Serialization
        delegate_missing_to :@workflow_version

        DESCRIPTOR_TYPE_MAPPING = {
            'cwl' => 'CWL',
            'nextflow' => 'NFL',
            'galaxy' => 'GALAXY'
        }

        def initialize(tool, workflow_version)
          @tool = tool
          @workflow_version = workflow_version
        end

        def id
          version.to_s
        end

        def tool_id
          @tool.id
        end

        def name
          title
        end

        def authors
          creators.map(&:name)
        end

        def descriptor_type
          [DESCRIPTOR_TYPE_MAPPING[workflow_class&.key]].compact
        end
      end
    end
  end
end
