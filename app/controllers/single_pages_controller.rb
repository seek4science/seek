class SinglePagesController < ApplicationController
  include Seek::AssetsCommon
  before_action :single_page_enabled
  before_action :project_membership_required, only: [:render_item_detail]
  respond_to :html, :js
  
  
  
  def show
    @single_page = true
    @project = Project.find(params[:id])
    @folders = project_folders
    # For creating new investigation and study in Project view page
    @investigation = Investigation.new
    @study = Study.new
    @assay = Assay.new

    respond_to do |format|
      format.html
    end
  end
  
  def index
  end

  def render_item_detail
    begin
      @single_page = true
      instance_variable_set("@item", params[:type].camelize.constantize.find(params[:id]))
      # To be accessed in associated template (e.g. Projects/view => @project)
      instance_variable_set("@#{params[:type]}", @item)
      find_display_asset(@item) if @item.respond_to?('latest_version')
      @item_controller = @item.class.name.underscore.pluralize
    rescue Exception => e
      error = e.message
    end
    respond_to do |format|
      if error
        format.js { render plain: error, status: :unprocessable_entity }
      else
        format.js
      end
    end
  end

  def single_page_enabled
    unless Seek::Config.project_single_page_enabled
      flash[:error]="Not available"
      redirect_to Project.find(params[:id])
    end
  end

  def project_folders
    project_folders =  ProjectFolder.root_folders(@project)
    if project_folders.empty?
      project_folders = ProjectFolder.initialize_default_folders(@project)
      ProjectFolderAsset.assign_existing_assets @project
    end
    project_folders
  end

end