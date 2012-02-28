

class FoldersController < ApplicationController
  before_filter :login_required
  before_filter :check_project
  before_filter :get_folder, :only=>[:create_folder, :destroy, :display_contents]
  before_filter :get_folders,:only=>[:index,:move_asset_to,:create_folder]

  in_place_edit_for :project_folder, :title
  in_place_edit_for :project_folder, :description

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
      format.html { redirect_to(:project_folders) }
    end
  end

  def nuke
      ProjectFolder.nuke @project
      redirect_to project_folders_path(@project)
  end

  def create_folder
    title=params[:title]
    @folder.add_child(title)
    @folder.save!
    render :update do |page|
      page.reload
    end

  end

  #moves the asset identified by :asset_id and :asset_type from this folder to the folder identified by :dest_folder_id
  def move_asset_to
    asset = params[:asset_type].constantize.find(params[:asset_id])
    this_folder=ProjectFolder.find(params[:id])
    dest_folder=ProjectFolder.find(params[:dest_folder_id])
    dest_folder.move_assets asset,this_folder
    render :update do |page|
      if (params[:dest_folder_element_id])
        page[params[:dest_folder_element_id]].update(dest_folder.label)
        #page[params[:dest_folder_element_id]].highlight
      end
      if (params[:origin_folder_element_id])
        page[params[:origin_folder_element_id]].update(this_folder.label)
        #page[params[:origin_folder_element_id]].highlight
      end
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
      store_folder_cookie()
    rescue Exception=>e
      Rails.logger.error("Error reading cookie for last folder browser - #{e.message}")
    end
    render :update do |page|
      page.replace_html "folder_contents",:partial=>"contents",:locals=>{:folder=>@folder}
    end
  end

  private

  def check_project
    @project = Project.find(params[:project_id])
    if @project.nil? || !current_user.person.projects.include?(@project)
      error("You must be a member of the project", "is invalid (not in project)")
    end
  end

  def get_folder
    id = params[:id]
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

end
