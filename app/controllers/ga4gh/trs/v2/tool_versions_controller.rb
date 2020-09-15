module Ga4gh
  module Trs
    module V2
      class ToolVersionsController < TrsBaseController
        before_action :get_tool
        before_action :get_version, only: [:show, :descriptor, :tests, :files, :containerfile]
        before_action :check_type, only: [:descriptor, :tests, :files]
        include ::RoCrateHandling

        def show
          respond_with(@tool_version, adapter: :attributes)
        end

        def index
          @tool_versions = @tool.versions
          respond_with(@tool_versions, adapter: :attributes)
        end

        def descriptor
          @tool.ro_crate do |crate|
            if params[:relative_path].present?
              file = crate.get(params[:relative_path])
            else
              file = crate.main_workflow
            end

            return trs_error(404, "No descriptor found#{ " at: #{params[:relative_path]}" if params[:relative_path].present?}") unless file

            if params[:type].downcase.start_with?('plain_')
              render plain: (file.remote? ? file.id.to_s : file.source.read)
            else
              @file_wrapper = FileWrapper.new(file)
              respond_with(@file_wrapper, adapter: :attributes)
            end
          end
        end

        def tests
          @tool.ro_crate do |crate|
            file_wrappers = crate.data_entities.select do |data_entity|
              data_entity.id.match?(/tests?\/.*\.json/)
            end.map do |data_entity|
              FileWrapper.new(data_entity)
            end

            respond_with(file_wrappers, adapter: :attributes)
          end
        end

        def files
          if request.query_parameters[:format] == 'zip'
            send_ro_crate(@tool_version.ro_crate_zip,
                          "workflow-#{@tool.id}-#{@tool_version.version}.crate.zip")
          else
            @tool.ro_crate do |crate|
              files = crate.data_entities.select do |data_entity|
                !(data_entity.is_a?(ROCrate::Directory) || data_entity.remote?)
              end.map do |data_entity|
                if data_entity == crate.main_workflow
                  type = 'PRIMARY_DESCRIPTOR'
                elsif data_entity.id == 'Dockerfile'
                  type = 'CONTAINERFILE'
                else
                  type = 'OTHER'
                end

                { path: data_entity.id, file_type: type }
              end

              respond_with(files.to_json)
            end
          end
        end

        def containerfile
          @tool.ro_crate do |crate|
            dockerfile = crate.get('Dockerfile')
            return trs_error(404, "No container file ('./Dockerfile') found for this tool version") unless dockerfile
            @file_wrapper = FileWrapper.new(dockerfile)
            respond_with([@file_wrapper], adapter: :attributes)
          end
        end

        private

        def get_version
          workflow_version = @tool.find_version(params[:version_id])
          return trs_error(404, "Couldn't find version with 'id'=#{params[:version_id]} for this tool") unless workflow_version
          @tool_version = ToolVersion.new(@tool, workflow_version)
        end

        def check_type
          if params[:type]
            descriptor = params[:type].sub(/plain_/i, '').upcase
            return trs_error(404, "Type: #{descriptor} not available") unless (@tool_version.descriptor_type || []).include?(descriptor)
          end
        end
      end
    end
  end
end
