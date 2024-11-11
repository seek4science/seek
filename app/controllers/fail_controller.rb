# A handy controller for testing failures: such as the error messages and exception notification
class FailController < ApplicationController
  
  before_action :is_user_admin_auth
  
  # GET /fail/?http_code=:code
  def index
    
    case params[:http_code]
      when "404"
        raise ActiveRecord::RecordNotFound.new
      when "500"
        x = nil
        x.hello_world
      when "406"
        raise ActionController::UnknownFormat
      when "503"
        raise RSolr::Error::ConnectionRefused
    end
    
    respond_to do |format|
      format.html { render plain: 'please use the http_code parameter, with a value of 404, 406, 500 or 503' }
    end
  end
  
end
