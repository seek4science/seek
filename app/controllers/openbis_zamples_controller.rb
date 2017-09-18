class OpenbisZamplesController < ApplicationController

  before_filter :get_project
  before_filter :get_endpoint


  def index
  end

  def get_endpoint
    @openbis_endpoint = OpenbisEndpoint.find(params[:openbis_endpoint_id])
  end

  def get_project
    @project = Project.find(params[:project_id])
  end
end