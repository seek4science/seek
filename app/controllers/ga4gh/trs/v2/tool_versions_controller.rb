module Ga4gh
  module Trs
    module V2
      class ToolVersionsController < ActionController::API
        before_action :get_tool
        before_action :get_version, only: [:show, :descriptor, :tests, :files, :containerfile]
        respond_to :json

        def show
          respond_with(@tool_version, adapter: :attributes)
        end

        def index
          @tool_versions = @tool.versions
          respond_with(@tool_versions, adapter: :attributes)
        end

        def descriptor
          raise NotImplementedError
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
          @tool = Ga4gh::Trs::V2::Tool.new(workflow)
        end

        def get_version
          pp @tool.find_version(params[:version_id])
          @tool_version = Ga4gh::Trs::V2::ToolVersion.new(@tool.find_version(params[:version_id]))
        end
      end
    end
  end
end