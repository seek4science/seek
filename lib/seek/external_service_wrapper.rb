module Seek
  module ExternalServiceWrapper

    def wrap_service(service_name, redirect_path, opts = {}, &block)
      begin
        block.call
      rescue RestClient::ResourceNotFound, SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
        external_service_error e, "#{service_name} error: service unreachable", redirect_path
      rescue RestClient::InternalServerError => e
        external_service_error e, "#{service_name} error: internal server error", redirect_path
      rescue RestClient::Forbidden, RestClient::Unauthorized => e
        external_service_error e, "#{service_name} error: service inaccessible", redirect_path
      rescue RestClient::RequestTimeout => e
        external_service_error e, "#{service_name} error: service timed out", redirect_path
      rescue RestClient::Exception => e
        external_service_error e, "#{service_name} error: #{e.http_code} #{e.response}", redirect_path
      rescue Exception => e
        if opts[:rescue_all]
          external_service_error e, "#{service_name} error: Unhandled error", redirect_path
        else
          raise e
        end
      end
    end

    private

    def external_service_error(exception, message, redirect_path)
      if Seek::Config.exception_notification_enabled
        ExceptionNotifier.notify_exception(exception, data: { message: "Error interacting with #{service_name}" })
      end
      flash[:error] = message
      redirect_to redirect_path
    end

  end
end
