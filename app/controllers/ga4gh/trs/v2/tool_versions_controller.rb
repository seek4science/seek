module Ga4gh
  module Trs
    module V2
      class ToolVersionsController < ActionController::API
        before_action :get_tool
        before_action :get_version, only: [:show, :descriptor, :tests, :files, :containerfile]
        before_action :check_type, only: [:descriptor, :tests, :files]
        respond_to :json

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

            if file.nil?
              respond_with({ code: 404, message: 'Not found' }, status: :not_found)
            else
              if params[:type].downcase.start_with?('plain_')
                render plain: (file.remote? ? file.id.to_s : file.source.read)
              else
                @file_wrapper = FileWrapper.new(file)
                respond_with(@file_wrapper, adapter: :attributes)
              end
            end
          end
        end

        def tests
          raise NotImplementedError
        end

        def files
          raise NotImplementedError
        end

        def containerfile
          raise NotImplementedError
        end

        private

        def get_tool
          workflow = Workflow.find(params[:id])
          @tool = Tool.new(workflow)
        end

        def get_version
          @tool_version = ToolVersion.new(@tool.find_version(params[:version_id]))
        end

        def check_type
          if params[:type]
            descriptor = params[:type].sub(/plain_/i, '').upcase
            unless @tool_version.descriptor_type == descriptor
              respond_with({ code: 404, message: "Type: #{descriptor} not available" }, status: :not_found)
            end
          end
        end
      end
    end
  end
end