class SinglePagesController < ApplicationController
  include Seek::AssetsCommon
  before_action :login_required, except: [:render_item_detail]
  before_action :single_page_enabled
  respond_to :html, :js
  
  def show
    @project = Project.find(params[:id])
    @folders = project_folders
    # For creating new investigation and study in Project view page
    @investigation = Investigation.new({})
    @study = Study.new({})
    @assay = Assay.new({})

    respond_to do |format|
      format.html
    end
  end

  def render_item_detail
    begin
      raise Exception, "not logged in" if !User.logged_in?
      instance_variable_set("@#{params[:type]}", params[:type].camelize.constantize.find(params[:id]))
      instance_variable_set("@#{params[:asset_type]}", params[:asset_type].camelize.constantize.find(params[:asset_id])) if params[:asset_type]
      @asset = @data_file || @document || @sop
      find_display_asset(@asset) if @asset
      @asset ||= @assay if @assay
      @asset_controller = @asset.class.name.underscore.pluralize
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
    project_folders = ProjectFolder.root_folders(@project)
    if project_folders.empty?
      project_folders = ProjectFolder.initialize_default_folders(@project)
      ProjectFolderAsset.assign_existing_assets @project
    end
    project_folders
  end

end
