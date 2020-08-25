module Ga4gh
  module Trs
    module V2
      class ToolsController < ActionController::API
        before_action :get_workflow, only: [:show]
        respond_to :json

        def show
          respond_with(@workflow)
        end

        def index
          @workflows = Workflow.all
          respond_with(@workflows)
        end

        private

        def get_workflow
          @workflow = Workflow.find(parmas[:id])
        end
      end
    end
  end
end