class OpenbisEndpointsController < ApplicationController
  include Seek::AssetsStandardControllerActions

  respond_to :html

  include Seek::DestroyHandling

  before_filter :openbis_enabled?

  before_filter :get_project
  before_filter :project_required, except: [:show_dataset_files]
  before_filter :project_member?, except: [:show_dataset_files]
  before_filter :project_can_admin?, except: [:browse, :add_dataset, :show_dataset_files, :show_items, :show_item_count]
  before_filter :authorise_show_dataset_files, only: [:show_dataset_files]
  before_filter :get_endpoints, only: [:index, :browse]
  before_filter :get_endpoint, only: [:add_dataset, :show_item_count, :show_items, :edit, :update, :show_dataset_files, :refresh_metadata_store, :destroy]

  def index
    respond_with(@project, @openbis_endpoints)
  end

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

  def add_dataset
    perm_id = params[:dataset_perm_id]
    fail 'No perm_id passed' unless perm_id
    @data_file = DataFile.build_from_openbis(@openbis_endpoint, params[:dataset_perm_id])
    redirect_to @data_file if @data_file.save
  end

  def browse
    respond_with(@project, @openbis_endpoints)
  end

  def create
    @openbis_endpoint = @project.openbis_endpoints.build(openbis_endpoint_params)
    save_and_respond 'The space was successfully created.'
  end

  def refresh_metadata_store
    @openbis_endpoint.clear_metadata_store if @openbis_endpoint.test_authentication
    show_items
  end

  ## AJAX calls

  def show_dataset_files
    if @data_file
      dataset = @data_file.content_blob.openbis_dataset
    else
      dataset = Seek::Openbis::Dataset.new(@openbis_endpoint, params[:perm_id])
    end

    respond_to do |format|
      format.html { render(partial: 'dataset_files_list', locals: { dataset: dataset, data_file: @data_file }) }
    end
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

  def show_item_count
    respond_to do |format|
      format.html { render(text: "#{@openbis_endpoint.space.dataset_count} DataSets found") }
    end
  end

  def show_items
    respond_to do |format|
      format.html { render(partial: 'show_items_for_space', locals: { openbis_endpoint: @openbis_endpoint }) }
    end
  end

  private

  def openbis_endpoint_params
    params.require(:openbis_endpoint).permit(:project_id, :web_endpoint, :as_endpoint, :dss_endpoint,
                                             :username, :password, :refresh_period_mins, :space_perm_id)
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
    @project = Project.find(params[:project_id])
  end

  def project_can_admin?
    unless @project.can_be_administered_by?(current_user)
      error('Insufficient privileges', 'is invalid (insufficient_privileges)')
      return false
    end
  end

  def project_member?
    unless @project.has_member?(User.current_user)
      error('Must be a member of the project', 'No permission')
      return false
    end
  end

  # whether the dataset files can be shown. Depends on whether viewing a data file or now.
  # if data_file_id is present then the access controls on that data file is checked, otherwise needs to be a project member
  def authorise_show_dataset_files
    @data_file = DataFile.find_by_id(params[:data_file_id])
    if @data_file
      unless @data_file.can_download?
        error('DataFile cannot be accessed', 'No permission')
        return false
      end
    else
      project_member?
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
