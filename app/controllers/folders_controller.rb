class FoldersController < ApplicationController
  before_filter :login_required
  before_filter :check_project

  def show
    respond_to do |format|
      format.html
    end
  end

  def index
    @folders = project_folders
    respond_to do |format|
      format.html
    end
  end

  def nuke
      ProjectFolder.nuke @project
      redirect_to project_folders_path(@project)
  end

  def display_contents
    folder = ProjectFolder.find(params[:id])
    render :update do |page|
      page.replace_html "folder_contents",:partial=>"contents",:locals=>{:folder=>folder}
    end
  end

  private

  def check_project
    @project = Project.find(params[:project_id])
    if @project.nil? || !current_user.person.projects.include?(@project)
      error("You must be a member of the project", "is invalid (not in project)")
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
