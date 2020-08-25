module Ga4gh
  module Trs
    module V2
      class ToolsController < ActionController::API
        before_action :get_tool, only: [:show]
        respond_to :json

        def show
          respond_with(@tool, adapter: :attributes)
        end

        def index
          @tools = Workflow.all.map { |workflow| Ga4gh::Trs::V2::Tool.new(workflow) }
          respond_with(@tools, adapter: :attributes)
        end

        private

        def get_tool
          workflow = Workflow.find(params[:id])
          @tool = Ga4gh::Trs::V2::Tool.new(workflow)
        end
      end
    end
  end
end