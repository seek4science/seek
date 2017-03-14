module Seek
  module Errors
    # Handles the final exception thrown, and displays the appropriate error page for that Error and response code
    module ControllerErrorHandling
      ERROR_MAP = {
        Exception => 500,
        ActionController::RoutingError => 404,
        ::AbstractController::ActionNotFound => 404,
        ActionController::UnknownController => 406,
        ActiveRecord::RecordNotFound => 404

      }

      def self.included(base)
        unless Rails.application.config.consider_all_requests_local
          base.rescue_from Exception, with: :render_application_error
        end
      end

      def render_application_error(exception)
        logger.error "ERROR - #{exception.class.name} (#{exception.message})"
        status = error_response_code(exception)
        exception_notification(status, exception)
        respond_to do |format|
          format.html { render template: "errors/error_#{status}", layout: 'layouts/errors', status: status }
          format.all { render nothing: true, status: status }
        end
      end

      def error_response_code(exception)
        ERROR_MAP[exception.class] || 500
      end

      def exception_notification(status, exception)
        unless !Seek::Config.exception_notification_enabled || status == 404
          begin
            ExceptionNotifier::Notifier.exception_notification(request.env, exception).deliver
          rescue
            logger.error "ERROR - #{exception.class.name} (#{exception.message})"
          end
        end
      end
    end
  end
end
