module Ga4gh
  module Trs
    module V2
      class TrsBaseController < ::ApplicationController
        respond_to :json, :plain

        after_action :set_content_type

        def set_content_type
          self.content_type = "application/json"
        end

        private

        def get_tool
          workflow = Workflow.find_by_id(params[:id])
          return trs_error(404, "Couldn't find tool with 'id'=#{params[:id]}") unless workflow
          return trs_error(403, "Access to this tool is restricted") unless workflow.can_view?
          @tool = Tool.new(workflow)
        end

        def trs_error(code, message)
          respond_with({ code: code, message: message }, adapter: :attributes, status: code)
        end
      end
    end
  end
end
