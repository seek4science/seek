class JermController < ApplicationController
  before_filter :login_required
  before_filter :is_user_admin_auth

  def index
    
  end
end
