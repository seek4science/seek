require 'white_list_helper'

class ProjectsController < ApplicationController
  include WhiteListHelper
  
  before_filter :login_required
  before_filter :is_user_admin_auth, :except=>[:index, :show, :edit, :update, :request_institutions]
  before_filter :editable_by_user, :only=>[:edit,:update]
  
  before_filter :set_parameters_for_sharing_form, :only => [ :new, :edit ]

  def auto_complete_for_organism_name
    render :json => Project.organism_counts.map(&:name).to_json
  end

  # GET /projects
  # GET /projects.xml
  def index   
    @projects = Project.paginate :page=>params[:page]
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @projects.to_xml(:except=>["site_credentials","site_root_uri"])  }
    end    
  end

  # GET /projects/1
  # GET /projects/1.xml
  def show
    @project = Project.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @project.to_xml(:except=>["site_credentials","site_root_uri"]) }
    end
  end

  # GET /projects/new
  # GET /projects/new.xml
  def new

    @project = Project.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @project }
    end
  end

  # GET /projects/1/edit
  def edit
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
        @project.organism_list = session[possible_unsaved_data][:organism][:list] if session[possible_unsaved_data][:organism]
      end
      
      # clear the session data anyway
      session[possible_unsaved_data] = nil
    end
  end

  # POST /projects
  # POST /projects.xml
  def create
    @project = Project.new(params[:project])

    respond_to do |format|
      if @project.save
        
        policy_err_msg = Policy.create_or_update_default_policy(@project, current_user, params)
        
        if policy_err_msg.blank?
          flash[:notice] = 'Project was successfully created.'
          format.html { redirect_to(@project) }
          format.xml  { render :xml => @project, :status => :created, :location => @project }
        else
          flash[:notice] = "Project was successfully created. However some problems occurred, please see these below.</br></br><span style='color: red;'>" + policy_err_msg + "</span>"
          format.html { redirect_to :controller => 'projects', :id => @project, :action => "edit" }
        end
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
    
    # extra check required to see if any avatar was actually selected (or it remains to be the default one)
    avatar_id = params[:project].delete(:avatar_id).to_i
    @project.avatar_id = ((avatar_id.kind_of?(Numeric) && avatar_id > 0) ? avatar_id : nil)
    
    respond_to do |format|
      if @proect.update_attributes(params[:project])
        
        policy_err_msg = Policy.create_or_update_default_policy(@project, current_user, params)
        
        if policy_err_msg.blank?
          flash[:notice] = 'Project was successfully updated.'
          format.html { redirect_to(@project) }
          format.xml  { head :ok }
        else
          flash[:notice] = "Project was successfully updated. However some problems occurred, please see these below.</br></br><span style='color: red;'>" + policy_err_msg + "</span>"
          format.html { redirect_to :controller => 'projects', :id => @project, :action => "edit" }
        end
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
  
  protected
  
    def set_parameters_for_sharing_form
    policy = nil
    policy_type = ""

    # obtain a policy to use
    if defined?(@project)
      if @project.default_policy
        policy = @project.default_policy
        policy_type = "project"
      end
    end

    unless policy
      # several scenarios could lead to this point:
      # 1) this is a "new" action - no Model exists yet; use default policy:
      #    - if current user is associated with only one project - use that project's default policy;
      #    - if current user is associated with many projects - use system default one;
      # 2) this is "edit" action - Model exists, but policy wasn't attached to it;
      #    (also, Model wasn't attached to a project or that project didn't have a default policy) --
      #    hence, try to obtain a default policy for the contributor (i.e. owner of the Model) OR system default
      policy = Policy.system_default(current_user)
      #Set the sharing scope to all_registered_users, instead of private, because if private only the system
      # would be able to view the resource, which is pointless.
      policy.sharing_scope = Policy::ALL_REGISTERED_USERS  
      policy_type = "system"
      
    end

    # set the parameters
    # ..from policy
    @policy = policy
    @policy_type = policy_type
    @sharing_mode = policy.sharing_scope
    @access_mode = policy.access_type
    @use_custom_sharing = (policy.use_custom_sharing == true || policy.use_custom_sharing == 1)
    @use_whitelist = (policy.use_whitelist == true || policy.use_whitelist == 1)
    @use_blacklist = (policy.use_blacklist == true || policy.use_blacklist == 1)

    # ..other
    @resource_type = "Project"
    @favourite_groups = current_user.favourite_groups

    @all_people_as_json = Person.get_all_as_json
  end

  private  

  def editable_by_user
    @project = Project.find(params[:id])
    unless current_user.is_admin? || @project.can_be_edited_by?(current_user)
      error("Insufficient priviledges", "is invalid (insufficient_priviledges)")
      return false
    end
  end


  
end
