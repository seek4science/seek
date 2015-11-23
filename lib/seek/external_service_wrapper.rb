module Seek
  module ExternalServiceWrapper
    
    def wrap_service(service_name, redirect_path, &block)
      begin
        block.call
      rescue RestClient::ResourceNotFound, SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        external_service_error "#{service_name} server unreachable", redirect_path
      rescue RestClient::InternalServerError
        external_service_error "#{service_name} server internal error", redirect_path
      rescue RestClient::Forbidden, RestClient::Unauthorized
        external_service_error "#{service_name} server inaccessible", redirect_path
      rescue RestClient::RequestTimeout
        external_service_error "#{service_name} server timed out", redirect_path
      rescue RestClient::Exception => e
        external_service_error "#{service_name} server error: #{e.http_code} #{e.response}", redirect_path
      end
    end

    private

    def external_service_error(message, redirect_path)
      flash[:error] = message
      redirect_to redirect_path
    end
    
  end
end
