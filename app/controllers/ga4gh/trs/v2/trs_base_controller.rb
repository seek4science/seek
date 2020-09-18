module Ga4gh
  module Trs
    module V2
      class TrsBaseController < ::ApplicationController
        respond_to :json, :text

        before_action :set_format
        before_action :check_trs_enabled
        after_action :set_content_type

        private

        def set_format
          # Hack because the way rails handles formats/`Accept` is crap
          request.format = :json if request.format.html?
        end

        def set_content_type
          # Needed because otherwise it wrongly gets the JSON-API MIME type
          self.content_type = "application/json" if request.format.json?
        end

        def check_trs_enabled
          trs_error(404, "TRS API is not enabled on this instance") unless Seek::Config.ga4gh_trs_api_enabled
        end

        def get_tool
          workflow = Workflow.find_by_id(params[:id])
          return trs_error(404, "Couldn't find tool with 'id'=#{params[:id]}") unless workflow&.can_view?
          @tool = Tool.new(workflow)
        end

        def trs_error(code, message)
          respond_with({ code: code, message: message }, adapter: :attributes, status: code)
        end
      end
    end
  end
end
