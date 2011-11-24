class ApplicationController < ActionController::Base
  def logged_in?
    true
  end
  
  def current_user
    @current_user ||= User.find(1)
  end
end
