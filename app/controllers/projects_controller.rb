class ProjectsController < ApplicationController
  
  before_filter :login_required
  before_filter :is_user_admin_auth, :except=>[:index, :show, :edit,:update]
  before_filter :editable_by_user, :only=>[:edit,:update]


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
  end

  # POST /projects
  # POST /projects.xml
  def create
    @project = Project.new(params[:project])

    if !params[:organism].nil?
      organism_list = params[:organism][:list]
      @project.organism_list=organism_list
    end

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

    #update tags for organism
    if !params[:organism].nil?
      organism_list = params[:organism][:list]
      @project.organism_list=organism_list
    end
    
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

  private

  def editable_by_user
    @project = Project.find(params[:id])
    unless current_user.is_admin? || @project.can_be_edited_by?(current_user)
      error("Insufficient priviledged", "is invalid (insufficient_priviledges)")
      return false
    end
  end
end
