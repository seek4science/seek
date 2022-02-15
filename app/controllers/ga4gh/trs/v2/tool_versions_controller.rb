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
              path = params[:relative_path]
              entry = crate.find_entry(params[:relative_path])
            else
              path = crate.main_workflow.id
              entry = crate.main_workflow&.source
            end

            return trs_error(404, "No descriptor found#{ " at: #{params[:relative_path]}" if params[:relative_path].present?}") unless entry

            if params[:type].downcase.start_with?('plain_')
              respond_to do |format|
                format.all { render plain: (entry.remote? ? entry.uri : entry.read) }
              end
            else
              @file_wrapper = FileWrapper.new(entry, path: path, tool_version: @tool_version)
              respond_to do |format|
                format.json { render json: @file_wrapper, adapter: :attributes }
                format.text { render plain: (entry.remote? ? entry.uri : entry.read) }
              end
            end
          end
        end

        def tests
          @tool.ro_crate do |crate|
            file_wrappers = crate.entries.map do |path, entry|
              FileWrapper.new(entry) if path.match?(/\Atests?\/.*\.json/)
            end.compact

            respond_with(file_wrappers, adapter: :attributes)
          end
        end

        def files
          if request.query_parameters[:format] == 'zip'
            send_ro_crate(@tool_version.ro_crate_zip, "workflow-#{@tool.id}-#{@tool_version.version}.crate.zip")
          else
            respond_with(@tool_version.list_files.to_json)
          end
        end

        def containerfile
          @tool.ro_crate do |crate|
            entry = crate.find_entry('Dockerfile')
            return trs_error(404, "No container file ('./Dockerfile') found for this tool version") unless entry
            @file_wrapper = FileWrapper.new(entry)
            respond_to do |format|
              format.json { render json: [@file_wrapper], adapter: :attributes }
              format.text { render plain: (entry.remote? ? entry.uri : entry.read) } # What to do if multiple container files? Maybe concat them all..
            end
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
