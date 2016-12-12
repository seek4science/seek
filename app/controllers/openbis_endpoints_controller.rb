class OpenbisEndpointsController < ApplicationController
  respond_to :html

  before_filter :get_project
  before_filter :project_required
  before_filter :project_can_admin?
  before_filter :get_spaces,only:[:index]


  def index
    respond_with(@openbis_spaces)
  end

  def new
    @openbis_space=OpenbisEndpoint.new
    @openbis_space.project=@project
    respond_with(@openbis_space)
  end

  def edit
    @openbis_space=OpenbisEndpoint.find(params[:id])
    respond_with(@openbis_space)
  end

  def update
    @openbis_space=OpenbisEndpoint.find(params[:id])
    respond_with(@project,@openbis_space) do |format|
      if @openbis_space.update_attributes(params[:openbis_space])
        flash[:notice] = 'The space was successfully updated.'
        format.html {redirect_to project_openbis_endpoints_path(@project)}
      end
    end
  end

  def create
    @openbis_space=@project.openbis_spaces.build(params[:openbis_space])
    respond_with(@project,@openbis_space) do |format|
      if @openbis_space.save
        flash[:notice] = 'The space was successfully associated with the project.'
        format.html {redirect_to project_openbis_endpoints_path(@project)}
      end
    end
  end

  def test_endpoint
    space = OpenbisEndpoint.new(params[:openbis_space])
    result = space.test_authentication

    respond_to do |format|
      format.json {render(json:{result:result})}
    end
  end

  def fetch_spaces
    space = OpenbisEndpoint.new(params[:openbis_space])
    respond_to do |format|
      format.html {render partial:'available_spaces',locals:{space:space}}
    end
  end

  ### Filters

  def project_required
    return false unless @project
  end

  def get_spaces
    @openbis_spaces=@project.openbis_spaces
  end

  def get_project
    @project=Project.find(params[:project_id])
  end

  def project_can_admin?
    unless @project.can_be_administered_by?(current_user)
      error("Insufficient privileges", "is invalid (insufficient_privileges)")
      return false
    end
  end

end