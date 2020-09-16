module Ga4gh
  module Trs
    module V2
      class TrsBaseController < ::ApplicationController
        respond_to :json, :plain

        before_action :check_trs_enabled
        after_action :set_content_type

        def set_content_type
          self.content_type = "application/json"
        end

        private

        def check_trs_enabled
          trs_error(403, "TRS API is not enabled for this instance") unless Seek::Config.ga4gh_trs_api_enabled
        end

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
