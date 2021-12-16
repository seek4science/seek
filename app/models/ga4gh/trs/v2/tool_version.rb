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
            'galaxy' => 'GALAXY',
            'snakemake' => 'SMK'
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

        def list_files
          files = []

          ro_crate do |crate|
            crate.entries.each do |path, entry|
              next if entry.directory?
              if crate.main_workflow && path == crate.main_workflow.id
                type = 'PRIMARY_DESCRIPTOR'
              elsif path == 'Dockerfile'
                type = 'CONTAINERFILE'
              else
                type = 'OTHER'
              end

              files << { path: path, file_type: type }
            end
          end

          files
        end

        def author
          authors
        end
      end
    end
  end
end
