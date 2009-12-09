class JermController < ApplicationController
  before_filter :login_required
  before_filter :is_user_admin_auth

  def index
    
  end

  def test
    project_id=params[:project]
    username=params[:name]
    password=params[:pwd]

    @project=Project.find(project_id)

    begin
      harvester = Jerm::CosmicHarvester.new username,password
      @results = harvester.update
    rescue

    end

    render :update do |page|
      page.replace_html :results,:partial=>"results",:object=>@results      
    end

    
  end
  
end
