module Seek
  module ExternalServiceWrapper
    def wrap_service(service_name, strategy, opts = {}, &block)
      block.call
    rescue RestClient::ResourceNotFound, SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
      external_service_error e, service_name, 'Service unreachable', strategy
    rescue RestClient::InternalServerError => e
      external_service_error e, service_name, 'Internal server error', strategy
    rescue RestClient::Forbidden, RestClient::Unauthorized => e
      external_service_error e, service_name, 'Service inaccessible', strategy
    rescue RestClient::RequestTimeout => e
      external_service_error e, service_name, 'Service timed out', strategy
    rescue RestClient::Exception => e
      external_service_error e, service_name, "(#{e.http_code}) #{e.response}", strategy
    rescue OpenURI::HTTPError => e
      external_service_error e, service_name, e.message, strategy
    rescue Exception => e
      if opts[:rescue_all]
        external_service_error e, service_name, 'Unhandled error', strategy
      else
        raise e
      end
    end

    private

    def external_service_error(exception, service_name, message, strategy)
      message = "There was a problem communicating with #{service_name} - #{message}"
      Seek::Errors::ExceptionForwarder.send_notification(exception, data: { message: "Error interacting with #{service_name}" } )

      if strategy.respond_to?(:call)
        strategy.call(message)
      else
        flash[:error] = message
        redirect_to strategy
      end
    end
  end
end
