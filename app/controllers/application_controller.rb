# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
  include Recaptcha::Verify

require 'authenticated_system'

class ApplicationController < ActionController::Base
  include Seek::Errors::ControllerErrorHandling

  self.mod_porter_secret = PORTER_SECRET

  include CommonSweepers



  before_filter :log_extra_exception_data

  after_filter :log_event

  include AuthenticatedSystem

  around_filter :with_current_user
  def with_current_user
    User.with_current_user current_user do
        yield
    end
  end

  before_filter :profile_for_login_required
  #around_filter :silence_logging if Rails.env == 'production'
  def silence_logging
    Rails.logger.silence do
      yield
    end
  end


  before_filter :project_membership_required

  helper :all

  def strip_root_for_xml_requests
    #intended to use as a before filter on requests that lack a single root model.
    #XML requests are required to have a single root node. This assumes the root node
    #will be named xml. Turns a params hash like.. {:xml => {:param_one => "val", :param_two => "val2"}}
    # into {:param_one => "val", :param_two => "val2"}

    #This should probably be used with prepend_before_filter, since some filters might need this to happen so they can check params.
    #see sessions controller for an example usage
    params[:xml].each {|k,v| params[k] = v} if request.format.xml? and params[:xml]
  end

  def set_no_layout
    self.class.layout nil
  end

  def base_host
    request.host_with_port
  end

  def application_root
    return  "http://#{base_host}"
  end
  helper_method :application_root

  #Overridden from restful_authentication
  #Does a second check that there is a profile assigned to the user, and if not goes to the profile
  #selection page (GET people/select)
  def authorized?
    if super
      redirect_to(select_people_path) if current_user.person.nil?
      true
    else
      false
    end
  end

  def is_user_activated
    if Seek::Config.activation_required_enabled && current_user && !current_user.active?
      error("Activation of this account it required for gaining full access", "Activation required?")
      false
    end
  end

  def is_current_user_auth
    begin
      @user = User.where(["id = ?", current_user.try(:id)]).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error("User not found (id not authorized)", "is invalid (not owner)")
      return false
    end

    unless @user
      error("User not found (or not authorized)", "is invalid (not owner)")
      return false
    end
  end

  def is_user_admin_auth
    unless User.admin_logged_in?
      error("Admin rights required", "is invalid (not admin)")
      return false
    end
    return true
  end

  def is_admin_or_is_project_manager
    unless User.admin_logged_in? || User.project_manager_logged_in?
      error("You do not have the permission", "Not admin or #{t('project')} manager")
      return false
    end
  end

  def can_manage_announcements?
    User.admin_logged_in?
  end

  def logout_user
    current_user.forget_me if logged_in?
    cookies.delete :auth_token
    cookies.delete :open_id
    error = flash[:error]
    notice = flash[:notice]
    reset_session
    flash[:error] = error
    flash[:notice] = notice
  end

  #called via ajax to provide the full list of resources for the tabs
  def view_items_in_tab
    resource_type = params[:resource_type]
    resource_ids = (params[:resource_ids] || []).split(',')
    render :update do |page|
      if !resource_type.blank?
        clazz = resource_type.constantize
        resources = clazz.find_all_by_id(resource_ids)
        if clazz.respond_to?(:authorize_asset_collection)
          resources = clazz.authorize_asset_collection(resources,"view")
        else
          resources = resources.select &:can_view?
        end
        resources.sort!{|item,item2| item2.updated_at <=> item.updated_at}
        page.replace_html "#{resource_type}_list_items_container",
                          :partial => "assets/resource_list",
                          :locals => {:collection => resources,
                          :narrow_view => true,
                          :authorization_for_showing_already_done => true,
                          :actions_partial_disable=>false}
        page.visual_effect :toggle_blind, "view_#{resource_type}s", :duration => 0.05
        page.visual_effect :toggle_blind, "view_#{resource_type}s_and_extra", :duration => 0.05
      end
    end
  end

  def resource_in_tab
    resource_type = params[:resource_type]
    view_type = params[:view_type]
    scale_title = params[:scale_title] || ''

    if params[:actions_partial_disable] == "true"
      actions_partial_disable = true
    else
      actions_partial_disable = false
    end

     #params[:resource_ids] is passed as string, e.g. "id1, id2, ..."
    resource_ids = (params[:resource_ids] || '').split(',')
    clazz = resource_type.constantize
    resources = clazz.find_all_by_id(resource_ids)
    if clazz.respond_to?(:authorized_partial_asset_collection)
      authorized_resources = clazz.authorized_partial_asset_collection(resources,"view")
    elsif resource_type == 'Project' || resource_type == 'Institution'
      authorized_resources = resources
    elsif resource_type == "Person" && Seek::Config.is_virtualliver && User.current_user.nil?
      authorized_resources = []
    else
      authorized_resources = resources.select &:can_view?
    end

    render :update do |page|
        page.replace_html "#{scale_title}_#{resource_type}_#{view_type}",
                          :partial => "assets/resource_in_tab",
                          :locals => {:resources => resources,
                                      :scale_title => scale_title,
                                      :authorized_resources => authorized_resources,
                                      :view_type => view_type,
                                      :actions_partial_disable => actions_partial_disable}
    end
  end

  private

  def project_membership_required
    unless current_user.try(:person).try(:member?) or User.admin_logged_in?
      if current_user.try(:person)
        flash[:error] = "Only members of known projects, institutions or work groups are allowed to access seek. Please contact a Project Manager or Admin."
        respond_to do |format|
          format.html {redirect_to logout_path}
          format.json { render :json => {:status => 401, :error_message => flash[:error] } }
        end
      elsif ["new", "create"].include? params[:action]
        flash[:error] = "Only members of known projects, institutions or work groups are allowed to create new content."
        respond_to do |format|
          format.html do
            try_block {redirect_to eval("#{controller_name}_path")} or redirect_to root_url
            format.json { render :json => {:status => 401, :error_message => flash[:error] } }
          end
        end
      end
    end
  end

  def pal_or_admin_required
    unless User.admin_logged_in? || (User.pal_logged_in?)
      error("Admin or PAL rights required", "is invalid (not admin)")
      return false
    end
  end

  #used to suppress elements that are for virtualliver only or are still currently being worked on
  def virtualliver_only
    if !Seek::Config.is_virtualliver
      error("This feature is is not yet currently available","invalid route")
      return false
    end
  end


  def currently_logged_in
    current_user.person
  end

  def error(notice, message)
    flash[:error] = notice
     (err = User.new.errors).add(:id, message)

    respond_to do |format|
      format.html { redirect_to root_url }
    end
  end

  #The default for the number items in a page when paginating
  def default_items_per_page
    7
  end

  #required for the Savage Beast
  def admin?
    User.admin_logged_in?
  end

  def email_enabled?
    Seek::Config.email_enabled
  end

  def profile_for_login_required
    if User.current_user
      if User.current_user.person.nil?
        flash[:notice]="You have successfully registered your account, but now must select a profile, or create your own."
        redirect_to select_people_path
      end
    end
  end

  def translate_action action_name
    case action_name
      when 'show', 'index', 'view', 'search', 'favourite', 'favourite_delete',
          'comment', 'comment_delete', 'comments', 'comments_timeline', 'rate',
          'tag', 'items', 'statistics', 'tag_suggestions', 'preview', 'send_image'
        'view'

      when 'download', 'named_download', 'launch', 'submit_job', 'data', 'execute','plot', 'explore','visualise' ,
          'export_as_xgmml'
        'download'

      when 'edit', 'new', 'create', 'update', 'new_version', 'create_version',
          'destroy_version', 'edit_version', 'update_version', 'new_item',
          'create_item', 'edit_item', 'update_item', 'quick_add', 'resolve_link'
        'edit'

      when 'destroy', 'destroy_item'
        'delete'

      when 'manage'
          'manage'
      else
        nil
    end
  end

  def find_and_auth
    begin
      name = self.controller_name.singularize
      action = translate_action(action_name)

      return if action.nil?

      object = name.camelize.constantize.find(params[:id])

      if is_auth?(object, action)
        eval "@#{name} = object"
        params.delete :sharing unless object.can_manage?(current_user)
      else
        respond_to do |format|
          #TODO: can_*? methods should report _why_ you can't do what you want. Perhaps something similar to how active_record_object.save stores 'why' in active_record_object.errors
          if User.current_user.nil?
            flash[:error] = "You are not authorized to #{action} this #{name.humanize}, you may need to login first."
          else
            flash[:error] = "You are not authorized to #{action} this #{name.humanize}."
          end

          format.html do
            case action
              when 'publish'   then redirect_to object
              when 'manage'   then redirect_to object
              when 'edit'     then redirect_to object
              when 'download' then redirect_to object
              when 'delete' then redirect_to object
              else                 redirect_to eval "#{self.controller_name}_path"
            end
          end
          format.rdf { render :text => "You may not #{action} #{name}:#{params[:id]}", :status => :forbidden }
          format.xml { render :text => "You may not #{action} #{name}:#{params[:id]}", :status => :forbidden }
          format.json { render :text => "You may not #{action} #{name}:#{params[:id]}", :status => :forbidden }
        end
        return false
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        if eval("@#{name}").nil?
          flash[:error] = "The #{name.humanize} does not exist!"
        else
          flash[:error] = "You are not authorized to view #{name.humanize}"
        end
        format.rdf { render  :text=>"Not found",:status => :not_found }
        format.xml { render  :text=>"<error>404 Not found</error>",:status => :not_found }
        format.json { render :text=>"Not found", :status => :not_found }
        format.html { redirect_to eval "#{self.controller_name}_path" }
      end
      return false
    end
  end

  def is_auth? object, action
    if object.can_perform? action
      true
    elsif params[:code] && (action == 'view' || action == 'download')
      object.auth_by_code? params[:code]
    else
      false
    end
  end

  def log_event
    User.with_current_user current_user do
      c = self.controller_name.downcase
      a = self.action_name.downcase

      object = eval("@"+c.singularize)

      object=current_user if c=="sessions" #logging in and out is a special case

      #don't log if the object is not valid or has not been saved, as this will a validation error on update or create
      return if object.nil? || (object.respond_to?("new_record?") && object.new_record?) || (object.respond_to?("errors") && !object.errors.empty?)


      case c
        when "sessions"
          if ["create", "destroy"].include?(a)
            ActivityLog.create(:action => a,
                               :culprit => current_user,
                               :controller_name => c,
                               :activity_loggable => object,
                               :user_agent => request.env["HTTP_USER_AGENT"])
          end
        when "investigations", "studies", "assays", "specimens", "samples"
          if ["show", "create", "update", "destroy"].include?(a)
            check_log_exists(a, c, object)
            ActivityLog.create(:action => a,
                               :culprit => current_user,
                               :referenced => object.projects.first,
                               :controller_name => c,
                               :activity_loggable => object,
                               :data => object.title,
                               :user_agent => request.env["HTTP_USER_AGENT"])

          end
        when "data_files", "models", "sops", "publications", "presentations", "events"
          a = "create" if a == "upload_for_tool"
          a = "update" if a == "new_version"
          a = "inline_view" if a == "explore"
          if ["show", "create", "update", "destroy", "download", "inline_view"].include?(a)
            check_log_exists(a, c, object)
            ActivityLog.create(:action => a,
                               :culprit => current_user,
                               :referenced => object.projects.first,
                               :controller_name => c,
                               :activity_loggable => object,
                               :data => object.title,
                               :user_agent => request.env["HTTP_USER_AGENT"])
          end
        when "people"
          if ["show", "create", "update", "destroy"].include?(a)
            ActivityLog.create(:action => a,
                               :culprit => current_user,
                               :controller_name => c,
                               :activity_loggable => object,
                               :data => object.title,
                               :user_agent => request.env["HTTP_USER_AGENT"])
          end
        when "search"
          if a=="index"
            ActivityLog.create(:action => "index",
                               :culprit => current_user,
                               :controller_name => c,
                               :user_agent => request.env["HTTP_USER_AGENT"],
                               :data => {:search_query => object, :result_count => @results.count})
          end
        when "content_blobs"
          a = "inline_view" if a=="view_pdf_content"
          if a=="inline_view" || (a=="download" && params['intent'].to_s != 'inline_view')
            activity_loggable = object.asset
            ActivityLog.create(:action => a,
                               :culprit => current_user,
                               :referenced => object,
                               :controller_name => c,
                               :activity_loggable => activity_loggable,
                               :user_agent => request.env["HTTP_USER_AGENT"],
                               :data => activity_loggable.title)
          end
      end

      expire_activity_fragment_cache(c, a)
    end
  end

  def expire_activity_fragment_cache(controller,action)
    if action!="show"
      @@auth_types ||=  Seek::Util.authorized_types.collect{|t| t.name.underscore.pluralize}
      if action=="download"
        expire_download_activity
      elsif action=="create" && controller!="sessions"
        expire_create_activity
      elsif action=="destroy"
        expire_create_activity
        expire_download_activity
      elsif action=="update" && @@auth_types.include?(controller) #may have had is permission changed
        expire_create_activity
        expire_download_activity
        expire_resource_list_item_action_partial
      end
    end
  end


  def check_log_exists action,controllername,object
    if action=="create"
      a=ActivityLog.where(
          :activity_loggable_type=>object.class.name,
          :activity_loggable_id=>object.id,
          :controller_name=>controllername,
          :action=>"create").first
      
      logger.error("ERROR: Duplicate create activity log about to be created for #{object.class.name}:#{object.id}") unless a.nil?
    end
  end

  def permitted_filters
    #placed this in a seperate method so that other controllers could override it if necessary
    Seek::Util.persistent_classes.select {|c| c.respond_to? :find_by_id}.map {|c| c.name.underscore}
  end

  def apply_filters(resources)
    filters = params[:filter] || {}
    #apply_filters will be dispatching to methods based on the symbols in params[:filter].
    #Permitted filters protects us from shennanigans like params[:filter] => {:destroy => 'This will destroy your data'}
    filters.delete_if {|k,v| not (permitted_filters.include? k.to_s) }
    resources.select do |res|
      filters.all? do |filter, value|
        filter = filter.to_s
        klass = filter.camelize.constantize
        value = klass.find_by_id value.to_i

        case
        #first the special cases
        when (filter == 'investigation' and res.respond_to? :assays) then res.assays.collect{|a| a.study.investigation_id}.include? value.id
        when (filter == 'study' and res.respond_to? :assays) then res.assays.collect{|a| a.study_id}.include? value.id
        when (filter == 'person' and res.class.is_asset?)    then (res.creators.include?(value) or res.contributor.try(:person) == value)
        when (filter == 'person' and res.respond_to? :owner) then res.send(:owner) == value
        when (filter == 'project' and res.respond_to? :projects_and_ancestors) then res.projects_and_ancestors.include? value
        when (filter == 'project' and res.class.name == "Assay") then Project.is_hierarchical? ? res.study.investigation.projects_and_ancestors.include?(value) : res.study.investigation.projects.include?(value)
        when (filter == 'project' and res.class.name == "Study") then Project.is_hierarchical? ? res.investigation.projects_and_ancestors.include?(value) : res.investigation.projects.include?(value)
        #then the general case
        when res.respond_to?(filter)                         then res.send(filter) == value
        when res.respond_to?(filter.pluralize)               then res.send(filter.pluralize).include? value
        #defaults to true, if a filter is irrelevant then it is silently ignored
        else true
        end
      end
    end
  end

  def log_extra_exception_data
      request.env["exception_notifier.exception_data"] = {
          :current_logged_in_user=>current_user
      }
  end


end



