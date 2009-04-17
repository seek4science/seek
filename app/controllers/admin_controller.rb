class AdminController < ApplicationController
  before_filter :login_required
  before_filter :is_user_admin_auth

  def show
    @topic=Topic.new
    @assay=Assay.new
  end
  
end
