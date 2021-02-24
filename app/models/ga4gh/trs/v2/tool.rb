module Ga4gh
  module Trs
    module V2
      # Decorator for a Workflow to make it appear as a GA4GH TRS Tool.
      class Tool
        include ActiveModel::Serialization
        delegate_missing_to :@workflow

        def initialize(workflow)
          @workflow = workflow
        end

        def id
          super.to_s
        end

        def name
          title
        end

        def organization
          projects.map(&:title).sort.join(', ')
        end

        def versions
          super.map { |v| ToolVersion.new(self, v) }
        end

        def toolclass
          ToolClass::WORKFLOW
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
      end
    end
  end
end
