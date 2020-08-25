module Ga4gh
  module Trs
    module V2
      class ToolVersionsController < ActionController::API
        before_action :get_workflow
        before_action :get_version, only: [:show, :descriptor, :tests, :files, :containerfile]

        def show

        end

        def index

        end

        def descriptor

        end

        def tests

        end

        def files

        end

        def containerfile

        end

        private

        def get_workflow
          @workflow = Workflow.find(parmas[:id])
        end

        def get_version
          @workflow_version = params.key?(:version_id) ? @workflow.find_version(params[:version_id]) : @workflow.latest_version
        end
      end
    end
  end
end