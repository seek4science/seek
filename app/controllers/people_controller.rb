class PeopleController < ApplicationController

  include Seek::AnnotationCommon

  before_filter :find_and_auth, :only => [:show, :edit, :update, :destroy]
  before_filter :current_user_exists,:only=>[:select,:userless_project_selected_ajax,:create,:new]
  before_filter :is_user_admin_auth,:only=>[:destroy]
  before_filter :is_user_admin_or_personless, :only=>[:new]
  before_filter :removed_params,:only=>[:update,:create]
  before_filter :do_projects_belong_to_project_manager_projects,:only=>[:administer_update]
  before_filter :editable_by_user, :only => [:edit, :update]
  before_filter :administerable_by_user, :only => [:admin, :administer_update]
  skip_before_filter :project_membership_required, :only => [:create, :new]
  skip_before_filter :profile_for_login_required,:only=>[:select,:userless_project_selected_ajax,:create]

  after_filter :reset_notifications, :only => [:administer_update]

  cache_sweeper :people_sweeper,:only=>[:update,:create,:destroy]
  include Seek::BreadCrumbs

  def reset_notifications
    # disable sending notifications for non_project members
    if !@person.member? && @person.notifiee_info.receive_notifications
      @person.notifiee_info.receive_notifications = false
      @person.notifiee_info.save
    end
  end
  def auto_complete_for_tools_name
    render :json => Person.tool_counts.map(&:name).to_json
  end

  def auto_complete_for_expertise_name
    render :json => Person.expertise_counts.map(&:name).to_json
  end
  
  protect_from_forgery :only=>[]
  
  # GET /people
  # GET /people.xml
  def index
    if (params[:discipline_id])
      @discipline=Discipline.find(params[:discipline_id])
      #FIXME: strips out the disciplines that don't match
      @people=Person.find(:all,:include=>:disciplines,:conditions=>["disciplines.id=?",@discipline.id])
      #need to reload the people to get their full discipline list - otherwise only get those matched above. Must be a better solution to this
      @people.each(&:reload)
    elsif (params[:project_role_id])
      @project_role=ProjectRole.find(params[:project_role_id])
      @people=Person.find(:all,:include=>[:group_memberships])
      #FIXME: this needs double checking, (a) not sure its right, (b) can be paged when using find.
      @people=@people.select{|p| !(p.group_memberships & @project_role.group_memberships).empty?}
    end

    unless @people
      if (params[:page].blank? || params[:page]=='latest' || params[:page]=="all")
        @people = Person.active
      else
        @people = Person.all
      end
      @people = apply_filters(@people).select(&:can_view?).reject {|p| p.projects.empty? }
      @people=Person.paginate_after_fetch(@people, :page=>params[:page])
    else
      @people = @people.select(&:can_view?).reject {|p| p.projects.empty?}
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml
    end
  end

  # GET /people/1
  # GET /people/1.xml
  def show                
    respond_to do |format|
      format.html # show.html.erb
      format.xml
    end
  end

  # GET /people/new
  # GET /people/new.xml
  def new    
    @person = Person.new
    respond_to do |format|
      format.html { render :action=>"new" }
      format.xml  { render :xml => @person }
    end
  end

  # GET /people/1/edit
  def edit
    possible_unsaved_data = "unsaved_#{@person.class.name}_#{@person.id}".to_sym
    if session[possible_unsaved_data]
      # if user was redirected to this 'edit' page from avatar upload page - use session
      # data; alternatively, user has followed some other route - hence, unsaved session
      # data is most probably not relevant anymore
      if params[:use_unsaved_session_data]
        # NB! these parameters are admin settings and regular users won't (and MUST NOT)
        # be able to use these; admins on the other hand are most likely to never change
        # any avatars - therefore, it's better to hide these attributes so they never get
        # updated from the session
        #
        # this was also causing a bug: when "upload new avatar" pressed, then new picture
        # uploaded and redirected back to edit profile page; at this poing *new* records
        # in the DB for person's work group memberships would already be created, which is an
        # error (if the following 3 lines are ever to be removed, the bug needs investigation)
        session[possible_unsaved_data][:person].delete(:work_group_ids)        
        
        # update those attributes of a person that we want to be updated from the session
        @person.attributes = session[possible_unsaved_data][:person]
      end
      
      # clear the session data anyway
      session[possible_unsaved_data] = nil
    end
  end

  def admin
    respond_to do |format|
      format.html
    end
  end

  #GET /people/select
  #
  #Page for after registration that allows you to select yourself from a list of
  #people yet to be assigned, or create a new one if you don't exist
  def select
    @userless_projects=Project.with_userless_people

    #strip out project with no people with email addresses
    #TODO: can be made more efficient by putting into a direct query in Project.with_userless_people - but not critical as this is only used during registration
    @userless_projects = @userless_projects.select do |proj|
      !proj.people.find{|person| !person.email.nil? && person.user.nil?}.nil?
    end

    @userless_projects.sort!{|a,b|a.name<=>b.name}
    @person = Person.new(params[:openid_details]) #Add some default values gathered from OpenID, if provided.

    render :action=>"select"
  end

  # POST /people
  # POST /people.xml
  def create
    @person = Person.new(params[:person])
    redirect_action="new"

    set_tools_and_expertise(@person, params)
   
    registration = false
    registration = true if (current_user.person.nil?) #indicates a profile is being created during the registration process

    if registration    
      current_user.person=@person      
      @userless_projects=Project.with_userless_people
      @userless_projects.sort!{|a,b|a.name<=>b.name}
      is_sysmo_member=params[:sysmo_member]

      if (is_sysmo_member)
        member_details = ''
        member_details.concat(project_or_institution_details 'projects')
        member_details.concat(project_or_institution_details 'institutions')
      end

      redirect_action="select"
    end

    respond_to do |format|
      if @person.save && current_user.save
        #send notification email to admin and project managers, if a new member is registering as a new person
        if Seek::Config.email_enabled && registration && is_sysmo_member
          #send mail to admin
          Mailer.deliver_contact_admin_new_user_no_profile(member_details, current_user, base_host)

          #send mail to project managers
          project_managers = project_managers_of_selected_projects params[:projects]
          project_managers.each do |project_manager|
            Mailer.deliver_contact_project_manager_new_user_no_profile(project_manager, member_details, current_user, base_host)
          end
        end
        if (!current_user.active?)
          Mailer.deliver_signup(current_user, base_host)
          flash[:notice]="An email has been sent to you to confirm your email address. You need to respond to this email before you can login"
          logout_user
          format.html { redirect_to :controller => "users", :action => "activation_required" }
        else
          flash[:notice] = 'Person was successfully created.'
          if @person.only_first_admin_person?
            format.html { redirect_to registration_form_path(:during_setup=>"true") }
          else
            format.html { redirect_to(@person) }
          end

          format.xml { render :xml => @person, :status => :created, :location => @person }
        end

      else
        format.html { render :action => redirect_action }
        format.xml { render :xml => @person.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /people/1
  # PUT /people/1.xml
  def update
    @person.disciplines.clear if params[:discipline_ids].nil?

    # extra check required to see if any avatar was actually selected (or it remains to be the default one)
    
    avatar_id = params[:person].delete(:avatar_id).to_i
    @person.avatar_id = ((avatar_id.kind_of?(Numeric) && avatar_id > 0) ? avatar_id : nil)
    
    set_tools_and_expertise(@person,params)    

    if !@person.notifiee_info.nil?
      @person.notifiee_info.receive_notifications = (params[:receive_notifications] ? true : false) 
      @person.notifiee_info.save if @person.notifiee_info.changed?
    end

    
    respond_to do |format|
      if @person.update_attributes(params[:person]) && set_group_membership_project_role_ids(@person,params)
        @person.save #this seems to be required to get the tags to be set correctly - update_attributes alone doesn't [SYSMO-158]
        @person.touch #this makes sure any caches based on the cache key are invalided where the person would not normally be updated, such as changing disciplines or tags
        flash[:notice] = 'Person was successfully updated.'
        format.html { redirect_to(@person) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @person.errors, :status => :unprocessable_entity }
      end
    end
  end

    # PUT /people/1
  # PUT /people/1.xml
  def administer_update
    passed_params=    {:roles                 =>  User.admin_logged_in?,
                       :roles_mask            => User.admin_logged_in?,
                       :can_edit_projects     => (User.admin_logged_in? || (User.project_manager_logged_in? && !(@person.projects & current_user.try(:person).try(:projects).to_a).empty?)),
                       :can_edit_institutions => (User.admin_logged_in? || (User.project_manager_logged_in? && !(@person.projects & current_user.try(:person).try(:projects).to_a).empty?)),
                       :work_group_ids        => (User.admin_logged_in? || User.project_manager_logged_in?)}
    temp = params.clone
    params[:person] = {}
    passed_params.each do |param, allowed|
      params[:person]["#{param}"] = temp[:person]["#{param}"] if temp[:person]["#{param}"] and allowed
      params["#{param}"] = temp["#{param}"] if temp["#{param}"] and allowed
    end
    set_roles(@person, params) if User.admin_logged_in?

    respond_to do |format|
      if @person.update_attributes(params[:person])

        #clear subscriptions for non_project members
        if @person.projects.empty?
             @person.project_subscriptions = []
             @person.subscriptions = []
        end
        @person.save #this seems to be required to get the tags to be set correctly - update_attributes alone doesn't [SYSMO-158]

        flash[:notice] = 'Person was successfully updated.'
        format.html { redirect_to(@person) }
        format.xml  { head :ok }
      else
        format.html { render :action => "admin" }
        format.xml  { render :xml => @person.errors, :status => :unprocessable_entity }
      end
    end
  end

  def set_group_membership_project_role_ids person,params
    #FIXME: Consider updating to Rails 2.3 and use Nested forms to handle this more cleanly.
    prefix="group_membership_role_ids_"
    person.group_memberships.each do |gr|
      key=prefix+gr.id.to_s
      gr.project_roles.clear
      if params[key.to_sym]
        params[key.to_sym].each do |r|
          r=ProjectRole.find(r)
          gr.project_roles << r
        end
      end
    end
  end

  # DELETE /people/1
  # DELETE /people/1.xml
  def destroy
    @person.destroy

    respond_to do |format|
      format.html { redirect_to(people_url) }
      format.xml  { head :ok }
    end
  end

  def userless_project_selected_ajax
    project_id=params[:project_id]
    unless project_id=="0"
      proj=Project.find(project_id)
      #ignore people with no email address
      @people=proj.userless_people.select{|person| !person.email.blank? }
      @people.sort!{|a,b| a.last_name<=>b.last_name}
      render :partial=>"userless_people_list",:locals=>{:people=>@people}
    else
      render :text=>""
    end
    
  end
  
  def get_work_group
    people = nil
    project_id=params[:project_id]
    institution_id=params[:institution_id]    
    if institution_id == "0"
      project = Project.find(project_id)
      people = project.people
    else
      workgroup = WorkGroup.find_by_project_id_and_institution_id(project_id,institution_id)
      people = workgroup.people
    end
    people_list = people.collect{|p| [p.name, p.email, p.id]}
    respond_to do |format|
      format.json {
        render :json => {:status => 200, :people_list => people_list }
      }
    end
  end

  private
  
  def set_tools_and_expertise person,params
      exp_changed = person.tag_with_params params,"expertise"
      tools_changed = person.tag_with_params params,"tool"
      if immediately_clear_tag_cloud?
        expire_annotation_fragments("expertise") if exp_changed
        expire_annotation_fragments("tool") if tools_changed
      else
         RebuildTagCloudsJob.create_job
      end

  end

  def set_roles person, params
    roles = person.is_admin? ? ['admin'] : []
    if params[:roles]
      params[:roles].each_key do |key|
        roles << key
      end
    end
    person.roles=roles
  end


  def is_user_admin_or_personless
    unless User.admin_logged_in? || current_user.person.nil?
      error("You do not have permission to create new people","Is invalid (not admin)")
      return false
    end
  end

  def current_user_exists
    if !current_user
      redirect_to(:root)
    end
    !!current_user
  end

  #checks the params attributes and strips those that cannot be set by non-admins, or other policy
  def removed_params
    # make sure to update people/_form if this changes
    #                   param                 => allowed access?
    removed_params = [:roles, :roles_mask, :can_edit_projects, :can_edit_institutions, :work_group_ids]

    removed_params.each do |param|
      params[:person].delete(param) if params[:person]
      params.delete param if params
    end
  end
  def project_or_institution_details projects_or_institutions
    details = ''
    unless params[projects_or_institutions].blank?
        params[projects_or_institutions].each do |project_or_institution|
          project_or_institution_details= project_or_institution.split(',')
          if project_or_institution_details[0] == 'Others'
             details.concat("Other #{projects_or_institutions}: #{params["other_#{projects_or_institutions}"]}; ")
          else
             details.concat("#{projects_or_institutions.singularize.capitalize}: #{project_or_institution_details[0]}, Id: #{project_or_institution_details[1]}; ")
          end
        end
    end
    details
  end

  def project_managers_of_selected_projects projects_param
    project_manager_list = []
    unless projects_param.blank?
      projects_param.each do |project_param|
        project_detail = project_param.split(',')
        project = Project.find_by_id(project_detail[1])
        project_managers = project.try(:project_managers)
        project_manager_list |= project_managers unless project_managers.nil?
      end
    end
    project_manager_list
  end

  def do_projects_belong_to_project_manager_projects
      if (params[:person] and params[:person][:work_group_ids])
        if User.project_manager_logged_in? && !User.admin_logged_in?
          projects = []
          params[:person][:work_group_ids].each do |id|
            work_group = WorkGroup.find_by_id(id)
            project = work_group.try(:project)
            projects << project unless project.nil?
          end
        project_manager_projects = Project.is_hierarchical?? current_user.person.projects_and_descendants : current_user.person.projects
          flag = true
          projects.each do |project|
            flag = false if !project_manager_projects.include? project
          end
          if flag == false
            error("Project manager can not assign person to the projects that they are not in", "Is invalid")
          end
          return flag
        end
    end
  end

  def editable_by_user
    unless @person.can_be_edited_by?(current_user)
      error("Insufficient privileges", "is invalid (insufficient_privileges)")
      return false
    end
  end

  def administerable_by_user
    @person=Person.find(params[:id])
    unless @person.can_be_administered_by?(current_user)
      error("Insufficient privileges", "is invalid (insufficient_privileges)")
      return false
    end
  end
end
