class AdminController < ApplicationController
  before_filter :login_required
  before_filter :is_user_admin_auth

  def show
    
    
  end
  
end
