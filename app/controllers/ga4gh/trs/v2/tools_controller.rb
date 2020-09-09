module Ga4gh
  module Trs
    module V2
      class ToolsController < TrsBaseController
        before_action :get_tool, only: [:show]

        def show
          respond_with(@tool, adapter: :attributes)
        end

        def index
          @tools = Workflow.authorized_for('view').all.map { |workflow| Ga4gh::Trs::V2::Tool.new(workflow) }
          respond_with(@tools, adapter: :attributes)
        end

        private

        def get_tool
          workflow = Workflow.find(params[:id])
          respond_with({}, adapter: :attributes, status: :forbidden) unless workflow.can_view?
          @tool = Ga4gh::Trs::V2::Tool.new(workflow)
        end
      end
    end
  end
end
