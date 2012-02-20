class BrowserController < ApplicationController
  before_filter :login_required
  before_filter :check_project

  def show
    respond_to do |format|
      format.html
    end
  end

  def index
    @folders_json = folder_structure_as_json
    respond_to do |format|
      format.html
    end
  end

  #just a temporary action whilst developing
  def nuke
      ProjectFolder.nuke @project
      redirect_to project_browser_index_path(@project)
  end

  private

  def check_project
    @project = Project.find(params[:project_id])
    if @project.nil? || !current_user.person.projects.include?(@project)
      error("You must be a member of the project", "is invalid (not in project)")
    end
  end


  #provides the folder structure as json format to be used to construct the view
  def folder_structure_as_json
    json = "["
    project_folders.each do |pf|
      json << pf.to_json << ","
    end
    json << "]"
    puts json
    json
  end

  def project_folders
    project_folders = ProjectFolder.root_folders(@project)
    if project_folders.empty?
      project_folders = ProjectFolder.initialize_default_folders(@project)
      ProjectAssetFolder.assign_existing_assets @project
    end
    project_folders
  end

end
