class OpenbisEndpointsController < ApplicationController
  include Seek::AssetsStandardControllerActions

  respond_to :html

  include Seek::DestroyHandling

  before_filter :openbis_enabled?

  before_filter :get_endpoint, only: %i[show edit update refresh destroy reset_fatals]
  before_filter :get_project
  before_filter :project_required
  before_filter :project_member?
  before_filter :project_can_admin?, except: [:browse]
  before_filter :get_endpoints, only: %i[index show browse]

  def index
    respond_with(@project, @openbis_endpoints)
  end

  def show; end

  def new
    @openbis_endpoint = OpenbisEndpoint.new
    @openbis_endpoint.project = @project
    @openbis_endpoint.policy.permissions.build(contributor: @project, access_type: Seek::Config.default_associated_projects_access_type)
    respond_with(@openbis_endpoint)
  end

  def edit
    respond_with(@openbis_endpoint)
  end

  def update
    @openbis_endpoint.update_attributes(openbis_endpoint_params)
    save_and_respond 'The space was successfully updated.'
  end

  def save_and_respond(flash_msg)
    update_sharing_policies @openbis_endpoint
    respond_with(@project, @openbis_endpoint) do |format|
      if @openbis_endpoint.save
        flash[:notice] = flash_msg
        format.html { redirect_to project_openbis_endpoints_path(@project) }
      end
    end
  end
  def browse
    respond_with(@project, @openbis_endpoints)
  end

  def create
    @openbis_endpoint = @project.openbis_endpoints.build(openbis_endpoint_params)
    save_and_respond 'The space was successfully created.'
  end

  def refresh
    @openbis_endpoint.force_refresh_metadata
    redirect_to @openbis_endpoint
  end

  def reset_fatals
    @openbis_endpoint.reset_fatal_assets
    redirect_to @openbis_endpoint
  end

  def test_endpoint
    endpoint = OpenbisEndpoint.new(openbis_endpoint_params)
    result = endpoint.test_authentication

    respond_to do |format|
      format.json { render(json: { result: result }) }
    end
  end

  def fetch_spaces
    endpoint = OpenbisEndpoint.new(openbis_endpoint_params)
    respond_to do |format|
      format.html { render partial: 'available_spaces', locals: { endpoint: endpoint } }
    end
  end

  private

  def openbis_endpoint_params
    params.require(:openbis_endpoint).permit(:project_id, :web_endpoint, :as_endpoint, :dss_endpoint,
                                             :username, :password, :refresh_period_mins, :space_perm_id,
                                             :study_types, :assay_types)
  end

  ### Filters

  def project_required
    return false unless @project
  end

  def get_endpoints
    @openbis_endpoints = @project.openbis_endpoints
  end

  def get_endpoint
    @openbis_endpoint = OpenbisEndpoint.find(params[:id])
  end

  def get_project
    @project = @openbis_endpoint.project if @openbis_endpoint
    @project = Project.find(params[:project_id]) unless @openbis_endpoint
  end

  def project_can_admin?
    unless @project.can_be_administered_by?(current_user)
      error('Insufficient privileges', 'is invalid (insufficient_privileges)')
      false
    end
  end

  def project_member?
    unless @project.has_member?(User.current_user)
      error('Must be a member of the project', 'No permission')
      false
    end
  end

  # overides the after_filter callback from application_controller, as the behaviour needs to be
  # slightly different
  def log_event
    action = action_name.downcase
    if action == 'add_dataset' && @data_file
      User.with_current_user current_user do
        ActivityLog.create(action: 'create',
                           culprit: current_user,
                           controller_name: controller_name,
                           activity_loggable: @data_file,
                           data: @data_file.title,
                           user_agent: request.env['HTTP_USER_AGENT'],
                           referenced: @openbis_endpoint)
      end
    end
  end
end
