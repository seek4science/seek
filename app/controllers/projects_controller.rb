require 'white_list_helper'

class ProjectsController < ApplicationController
  include WhiteListHelper
  
  before_filter :login_required
  before_filter :is_user_admin_auth, :except=>[:index, :show, :edit, :update, :request_institutions]
  before_filter :editable_by_user, :only=>[:edit,:update]
  before_filter :set_tagging_parameters,:only=>[:edit,:new,:create,:update]


  def auto_complete_for_organism_name
    render :json => Project.organism_counts.map(&:name).to_json
  end

  # GET /projects
  # GET /projects.xml
  def index
    
    if (!params[:organisms].nil?)
      @organisms=params[:organisms]
      @projects=Project.tagged_with(@organisms,:on=>:organisms)
    else
      @projects = Project.find(:all, :page=>{:size=>default_items_per_page,:current=>params[:page]}, :order=>:name)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @projects }
    end
    
  end

  # GET /projects/1
  # GET /projects/1.xml
  def show
    @project = Project.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @project }
    end
  end

  # GET /projects/new
  # GET /projects/new.xml
  def new

    @tags_organisms = Project.organism_counts.sort{|a,b| a.name<=>b.name}

    @project = Project.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @project }
    end
  end

  # GET /projects/1/edit
  def edit
    @tags_organisms = Project.organism_counts.sort{|a,b| a.name<=>b.name}
    @project = Project.find(params[:id])
    
    possible_unsaved_data = "unsaved_#{@project.class.name}_#{@project.id}".to_sym
    if session[possible_unsaved_data]
      # if user was redirected to this 'edit' page from avatar upload page - use session
      # data; alternatively, user has followed some other route - hence, unsaved session
      # data is most probably not relevant anymore
      if params[:use_unsaved_session_data]
        # NB! these parameters are admin settings and can *occasionally* be used by super-users -
        # regular users won't (and MUST NOT) be able to use these; it's not likely for admins
        # or super-users to modify these along with participating institutions - therefore,
        # it's better not to update these from session
        #
        # this was also causing a bug: when "upload new avatar" pressed, then new picture
        # uploaded and redirected back to edit profile page; at this poing *new* records
        # in the DB for institutions that participate in this project would already be created, which is an
        # error (if the following line is ever to be removed, the bug needs investigation)
        session[possible_unsaved_data][:project].delete(:institution_ids)
        
        # update those attributes of a project that we want to be updated from the session
        @project.attributes = session[possible_unsaved_data][:project]
        @project.organism_list = session[possible_unsaved_data][:organism][:list]
      end
      
      # clear the session data anyway
      session[possible_unsaved_data] = nil
    end
  end

  # POST /projects
  # POST /projects.xml
  def create
    @project = Project.new(params[:project])

    set_organisms @project, params

    respond_to do |format|
      if @project.save
        flash[:notice] = 'Project was successfully created.'
        format.html { redirect_to(@project) }
        format.xml  { render :xml => @project, :status => :created, :location => @project }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @project.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /projects/1
  # PUT /projects/1.xml
  def update
    @project = Project.find(params[:id])
    #@project.work_groups.each{|wg| wg.destroy} if params[:project][:institutions].nil?

    set_organisms @project, params
    
    # extra check required to see if any avatar was actually selected (or it remains to be the default one)
    avatar_id = params[:project].delete(:avatar_id).to_i
    @project.avatar_id = ((avatar_id.kind_of?(Fixnum) && avatar_id > 0) ? avatar_id : nil)
    
    respond_to do |format|
      if @project.update_attributes(params[:project])
        flash[:notice] = 'Project was successfully updated.'
        format.html { redirect_to(@project) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @project.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/1
  # DELETE /projects/1.xml
  def destroy
    @project = Project.find(params[:id])
    @project.destroy

    respond_to do |format|
      format.html { redirect_to(projects_url) }
      format.xml  { head :ok }
    end
  end
  
  
  # returns a list of institutions for a project in JSON format
  def request_institutions
    # listing institutions for a project is public data, but still
    # we require login to protect from unwanted requests
    
    project_id = white_list(params[:id])
    institution_list = nil
    
    begin
      project = Project.find(project_id)
      institution_list = project.get_institutions_listing
      success = true
    rescue ActiveRecord::RecordNotFound
      # project wasn't found
      success = false
    end
    
    respond_to do |format|
      format.json {
        if success
          render :json => {:status => 200, :institution_list => institution_list }
        else
          render :json => {:status => 404, :error => "Couldn't find Project with ID #{project_id}."}
        end
      }
    end
  end

  private

  def set_organisms project,params
    tags=""
    params[:organism_autocompleter_selected_ids].each do |selected_id|
      tag=Tag.find(selected_id)
      tags << tag.name << ","
    end unless params[:organism_autocompleter_selected_ids].nil?
    params[:organism_autocompleter_unrecognized_items].each do |item|
      tags << item << ","
    end unless params[:organism_autocompleter_unrecognized_items].nil?

    project.organism_list=tags
    
  end

  def editable_by_user
    @project = Project.find(params[:id])
    unless current_user.is_admin? || @project.can_be_edited_by?(current_user)
      error("Insufficient priviledged", "is invalid (insufficient_priviledges)")
      return false
    end
  end

  def set_tagging_parameters
    organisms=Project.organism_counts.sort{|a,b| a.id<=>b.id}.collect{|t| {'id'=>t.id,'name'=>t.name}}
    @all_organisms_as_json=organisms.to_json
  end
  
end
