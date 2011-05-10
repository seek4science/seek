# A handy controller for testing failures: such as the error messages and exception notification
class FailController < ApplicationController
  
  before_filter :is_user_admin_auth
  
  # GET /fail/?http_code=:code
  def index
    puts "Current codes to send emails: #{ExceptionNotifier.send_email_error_codes.inspect}"
    
    case params[:http_code]
      when "404"
        raise ActiveRecord::RecordNotFound.new
      when "500"
        x = nil
        x.hello_world
      when "406"
        raise ActionController::UnknownController
    end
    
    respond_to do |format|
      format.html # index.html.erb
    end
  end
  
end
