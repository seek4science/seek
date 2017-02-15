class OpenbisEndpointsController < ApplicationController
  respond_to :html

  include Seek::DestroyHandling

  before_filter :openbis_enabled?

  before_filter :get_project
  before_filter :project_required
  before_filter :project_is_member?
  before_filter :project_can_admin?, except: [:browse, :add_dataset, :show_dataset_files, :show_items, :show_item_count]
  before_filter :get_endpoints, only: [:index, :browse]
  before_filter :get_endpoint, only: [:add_dataset, :show_item_count, :show_items, :edit, :update, :show_dataset_files, :refresh_browse_cache, :destroy]

  def index
    respond_with(@project, @openbis_endpoints)
  end

  def new
    @openbis_endpoint = OpenbisEndpoint.new
    @openbis_endpoint.project = @project
    respond_with(@openbis_endpoint)
  end

  def edit
    respond_with(@openbis_endpoint)
  end

  def update
    respond_with(@project, @openbis_endpoint) do |format|
      if @openbis_endpoint.update_attributes(params[:openbis_endpoint])
        flash[:notice] = 'The space was successfully updated.'
        format.html { redirect_to project_openbis_endpoints_path(@project) }
      end
    end
  end

  def add_dataset
    perm_id = params[:dataset_perm_id]
    fail 'No perm_id passed' unless perm_id
    @data_file = DataFile.build_from_openbis(@openbis_endpoint, params[:dataset_perm_id])
    redirect_to @data_file
  end

  def browse
    respond_with(@project, @openbis_endpoints)
  end

  def create
    @openbis_endpoint = @project.openbis_endpoints.build(params[:openbis_endpoint])
    respond_with(@project, @openbis_endpoint) do |format|
      if @openbis_endpoint.save
        flash[:notice] = 'The space was successfully associated with the project.'
        format.html { redirect_to project_openbis_endpoints_path(@project) }
      end
    end
  end

  def refresh_browse_cache
    @openbis_endpoint.clear_cache if @openbis_endpoint.test_authentication
    show_items
  end

  ## AJAX calls

  def show_dataset_files
    if data_file = DataFile.find_by_id(params[:data_file_id])
      dataset = data_file.content_blob.openbis_dataset
    else
      dataset = Seek::Openbis::Dataset.new(@openbis_endpoint, params[:perm_id])
    end

    respond_to do |format|
      format.html { render(partial: 'dataset_files_list', locals: { dataset: dataset, data_file: data_file }) }
    end
  end

  def test_endpoint
    endpoint = OpenbisEndpoint.new(params[:openbis_endpoint])
    result = endpoint.test_authentication

    respond_to do |format|
      format.json { render(json: { result: result }) }
    end
  end

  def fetch_spaces
    endpoint = OpenbisEndpoint.new(params[:openbis_endpoint])
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

  def project_is_member?
    unless @project.has_member?(User.current_user)
      error('Must be a member of the project', 'No permission')
      return false
    end
  end
end
