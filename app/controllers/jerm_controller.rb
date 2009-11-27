class JermController < ApplicationController
  before_filter :login_required
  before_filter :is_user_admin_auth

  def index
    
  end

  def test
    project_id=params[:project]
    username=params[:username]
    password=params[:password]

    @project=Project.find(project_id)

    
  end
end
