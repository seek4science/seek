module Ga4gh
  module Trs
    module V2
      class TrsBaseController < ::ApplicationController
        respond_to :json, :text

        before_action :set_format
        before_action :check_trs_enabled
        after_action :set_content_type

        rescue_from StandardError do |e|
          Rails.logger.error("TRS Error: #{e.message} - #{e.backtrace.join($/)}")
          raise e unless Rails.env.production? || Thread.current[:ignore_trs_errors]
          exception_notification(500, e) unless Rails.application.config.consider_all_requests_local
          trs_error(500, "An unexpected error occurred.")
        end

        rescue_from ActionController::RoutingError, ::AbstractController::ActionNotFound, ActiveRecord::RecordNotFound do |e|
          trs_error(404, "Not found.")
        end

        rescue_from ActionController::UnknownFormat do |e|
          trs_error(406, "Not acceptable.")
        end

        private

        def set_format
          # Hack because the way rails handles formats/`Accept` is crap
          request.format = :json if request.format.html?
        end

        def set_content_type
          # Needed because otherwise it wrongly gets the JSON-API MIME type
          self.content_type = "application/json" if content_type&.start_with?('application/vnd.api+json')
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
          respond_to do |format|
            format.json { render json: { code: code, message: message }, adapter: :attributes, root: '', status: code }
            format.text { render plain: "Error #{code} - #{message}", status: code }
          end
        end
      end
    end
  end
end
