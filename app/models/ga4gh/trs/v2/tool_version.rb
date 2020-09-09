module Ga4gh
  module Trs
    module V2
      # Decorator for a Workflow::Version to make it appear as a GA4GH TRS Tool Version.
      class ToolVersion
        include ActiveModel::Serialization
        delegate_missing_to :@workflow_version

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
          t = case workflow_class&.key
              when 'CWL'
                'CWL'
              when 'Nextflow'
                'NFL'
              when 'Galaxy'
                'GALAXY'
              else
                nil
              end
          [t].compact
        end
      end
    end
  end
end
