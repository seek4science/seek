

class FoldersController < ApplicationController
  before_action :login_required
  before_action :check_project
  before_action :browser_enabled
  before_action :get_folder, :only=>[:create_folder, :destroy, :display_contents,:remove_asset]
  before_action :get_folders,:only=>[:index,:move_asset_to,:create_folder]
  before_action :get_asset, :only=>[:move_asset_to,:remove_asset]

  def show
    respond_to do |format|
      format.html
    end
  end

  def index
    respond_to do |format|
      format.html
    end
  end

  def destroy
    respond_to do |format|
      flash[:error]="Unable to delete this folder" if !@folder.destroy
      format.html {  Seek::Config.project_single_page_enabled ? redirect_to(single_page_path(@project))
         : redirect_to(:project_folders) }
    end
  end

  def nuke
      ProjectFolder.nuke @project
      redirect_to project_folders_path(@project)
  end

  def create_folder
    title=params[:title]
    if title.length>2
      @folder.add_child(title)
      @folder.save!
      respond_to do |format|
        format.js { render plain: '' }
      end
    else
      error_text="The name is too short, it must be 2 or more characters"
      respond_to do |format|
        format.js { render plain: error_text, status: 500 }
      end
    end

  end

  #moves the asset identified by :asset_id and :asset_type from this folder to the folder identified by :dest_folder_id
  def move_asset_to
    @origin_folder=resolve_folder params[:id]
    @dest_folder=resolve_folder params[:dest_folder_id]
    @dest_folder.move_assets @asset,@origin_folder
    respond_to do |format|
      format.js
    end
  end

  def remove_asset
    @folder.remove_assets @asset
    respond_to do |format|
      format.js
    end
  end

  def store_folder_cookie
    cooky=cookies[:folder_browsed_json]
    Rails.logger.error "Old cookie value: #{cooky}"
    cooky||={}.to_json
    folder_browsed=ActiveSupport::JSON.decode(cooky)
    folder_browsed[@project.id.to_s]=params[:id]
    Rails.logger.error "New cookie value: #{folder_browsed.to_json}"

    cookies[:folder_browsed_json]=folder_browsed.to_json
  end

  def display_contents
    begin
      store_folder_cookie
    rescue Exception=>e
      Rails.logger.error("Error reading cookie for last folder browser - #{e.message}")
    end
    respond_to do |format|
      format.js
    end
  end

  def set_project_folder_title
    @item = ProjectFolder.find(params[:id])
    @item.update_attribute(:title, params[:value])
    render plain: @item.title
  end

  def set_project_folder_description
    @item = ProjectFolder.find(params[:id])
    @item.update_attribute(:description, params[:value])
    render plain: @item.description
  end

  private

  def check_project
    @project = Project.find(params[:project_id])
    if @project.nil? || !current_person.projects.include?(@project)
      error("You must be a member of the #{t('project').downcase}", "is invalid (not in #{t('project').downcase})")
    end
  end

  def browser_enabled
    unless Seek::Config.project_browser_enabled || Seek::Config.project_single_page_enabled
      flash[:error]="Not available"
      redirect_to @project
    end
  end

  def get_folder
    id = params[:id]
    resolve_folder id
  end

  def resolve_folder id
    if id.start_with?("Assay")
      id=id.split("_")[1]
      assay = Assay.find(id)
      if assay.can_view?
        @folder = Seek::AssayFolder.new assay,@project
      else
        error("You cannot view the contents of that assay", "is invalid or not authorized")
      end
    else
      @folder = ProjectFolder.find(id)
    end
  end

  def get_folders
    @folders = project_folders
  end

  def project_folders
    project_folders = ProjectFolder.root_folders(@project)
    if project_folders.empty?
      project_folders = ProjectFolder.initialize_default_folders(@project)
      ProjectFolderAsset.assign_existing_assets @project
    end
    project_folders
  end

  def get_asset
    @asset = safe_class_lookup(params[:asset_type]).find(params[:asset_id])
    unless @asset.can_view?
      error("You cannot view the asset", "is invalid or not authorized")
    end
  end

end
