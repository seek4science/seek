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

  private

  def check_project
    @project = Project.find(params[:project_id])
    if @project.nil? || !current_user.person.projects.include?(@project)
      error("You must be a member of the project", "is invalid (not in project)")
    end
  end

  #will be replaced with a database model
  class ProjectFolder
    attr_accessor :label,:type,:children,:expanded, :editable

    def initialize
      @children = []
      @type = "text"
      @expanded = true
      @editable = true
    end

    def to_json
      json = "{"
      json << "type: '#{type}',"
      json << "label: '#{label}',"
      json << "className: 'fred',"
      json << "expanded: '#{expanded}'"
      if children.empty?
        json << ", children: []"
      else
        json << ", children: ["
        children.sort_by(&:label).each do |child|
          json << child.to_json << ","
        end
        json << "]"
      end
      json << "}"
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

  #returns an array of ProjectFolders
  def project_folders
    pf=ProjectFolder.new
    pf.label="models"

    pf2=ProjectFolder.new
    pf2.label="published"

    pf.children << pf2

    pf3=ProjectFolder.new
    pf3.label="unpublished"

    pf.children << pf3

    pf4=ProjectFolder.new
    pf4.label="accepted"

    pf3.children << pf4

    pf5=ProjectFolder.new
    pf5.label="data"

    pf6=ProjectFolder.new
    pf6.label="SOPs"

    pf7=ProjectFolder.new
    pf7.label="rough"
    pf.children << pf7

    [pf,pf5]
  end

end
