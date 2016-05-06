# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'authenticated_system'

class ApplicationController < ActionController::Base

  include Seek::Errors::ControllerErrorHandling
  include Seek::EnabledFeaturesFilter
  include Recaptcha::Verify

  self.mod_porter_secret = PORTER_SECRET

  include CommonSweepers

  before_filter :log_extra_exception_data

  #if the logged in user is currently partially registered, force the continuation of the registration process
  before_filter :partially_registered?

  after_filter :log_event

  include AuthenticatedSystem

  around_filter :with_current_user

  rescue_from "ActiveRecord::RecordNotFound", :with=>:render_not_found_error

  before_filter :project_membership_required,:only=>[:create,:new]

  before_filter :restrict_guest_user, :only => [:new, :edit, :batch_publishing_preview]
  helper :all

  layout Seek::Config.main_layout

  def with_current_user
    User.with_current_user current_user do
      yield
    end
  end

  def current_person
    current_user.try(:person)
  end

  def partially_registered?
    redirect_to register_people_path if (current_user && !current_user.registration_complete?)
  end

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
    true
  end

  def can_manage_announcements?
    User.admin_logged_in?
  end

  def logout_user
    current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
  end

  #MERGENOTE - put back for now, but needs modularizing, refactoring, and possibly replacing
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
    elsif resource_type == "Person" && Seek::Config.is_virtualliver && current_user.nil?
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

  def restrict_guest_user
    if current_user && current_user.guest?
      flash[:error] = "You cannot perform this action as a Guest User. Please sign in or register for an account first."
      if !request.env["HTTP_REFERER"].nil?
        redirect_to :back
      else
        redirect_to main_app.root_path
      end
    end
  end

  private

  def project_membership_required
    unless User.logged_in_and_member? || User.admin_logged_in?
      flash[:error] = "Only members of known projects, institutions or work groups are allowed to create new content."
      respond_to do |format|
        format.html do          
          object = eval("@"+controller_name.singularize)
          if !object.nil? && object.try(:can_view?)
            redirect_to object
          else
            path = nil
            begin
              path = eval("main_app.#{controller_name}_path")
            rescue NoMethodError => e
              logger.error("No path found for controller - #{controller_name}")
              path = main_app.root_path
            end
            redirect_to path
          end

        end
        format.json { render :json => {:status => 401, :error_message => flash[:error]} }
      end
    end
  end

  alias_method :project_membership_required_appended, :project_membership_required


  #used to suppress elements that are for virtualliver only or are still currently being worked on
  def virtualliver_only
    if !Seek::Config.is_virtualliver
      error("This feature is is not yet currently available","invalid route")
      return false
    end
  end

  def check_allowed_to_manage_types
    unless Seek::Config.type_managers_enabled
      error("Type management disabled", "...")
      return false
    end
    if current_user
      if current_user.can_manage_types?
        return true
      else
        error("Admin rights required to manage types", "...")
        return false
      end
    else
      error("You need to login first.", "...")
      return false
    end
  end

  def filter_protected_update_params(params)
    if params
      [:contributor_id, :contributor_type, :original_filename, :content_type, :content_blob_id, :created_at, :updated_at, :last_used_at].each do |column_name|
        params.delete(column_name)
      end

      params[:last_used_at] = Time.now
    end
    params
  end

  def error(notice, message)
    flash[:error] = notice

    respond_to do |format|
      format.html { redirect_to root_url }
    end
  end

  #required for the Savage Beast
  def admin?
    User.admin_logged_in?
  end

  def translate_action action_name
    case action_name
      when 'show', 'index', 'view', 'search', 'favourite', 'favourite_delete',
          'comment', 'comment_delete', 'comments', 'comments_timeline', 'rate',
          'tag', 'items', 'statistics', 'tag_suggestions', 'preview','runs','new_object_based_on_existing_one',
          'samples_table'
        'view'

      when 'download', 'named_download', 'launch', 'submit_job', 'data', 'execute','plot', 'explore','visualise' ,
          'export_as_xgmml', 'download_log', 'download_results', 'input', 'output', 'download_output', 'download_input',
          'view_result','compare_versions','simulate'
        'download'

      when 'edit', 'new', 'create', 'update', 'new_version', 'create_version',
          'destroy_version', 'edit_version', 'update_version', 'new_item',
          'create_item', 'edit_item', 'update_item', 'quick_add', 'resolve_link', 'describe_ports'
        'edit'

      when 'destroy', 'destroy_item', 'cancel'
        'delete'

      when 'manage', 'notification', 'read_interaction', 'write_interaction', 'report_problem', 'storage_report', 'select_sample_type'
          'manage'
      else
        nil
    end
  end

  #handles finding an asset, and responding when it cannot be found. If it can be found the item instance is set (e.g. @project for projects_controller)
  def find_requested_item
    name = self.controller_name.singularize
    object = name.camelize.constantize.find_by_id(params[:id])
    if (object.nil?)
      respond_to do |format|
        flash[:error] = "The #{name.humanize} does not exist!"
        format.rdf { render  :text=>"Not found",:status => :not_found }
        format.xml { render  :text=>"<error>404 Not found</error>",:status => :not_found }
        format.json { render :text=>"Not found", :status => :not_found }
        format.html { redirect_to eval "#{self.controller_name}_path" }
      end
    else
      eval "@#{name} = object"
    end
  end

  #handles finding and authorizing an asset for all controllers that require authorization, and handling if the item cannot be found
  def find_and_authorize_requested_item
    name = self.controller_name.singularize
    action = translate_action(action_name)

    return if action.nil?

    object = self.controller_name.classify.constantize.find(params[:id])

    if is_auth?(object, action)
      eval "@#{name} = object"
      params.delete :sharing unless object.can_manage?(current_user)
    else
      respond_to do |format|
        format.html do
          case action
            when 'publish', 'manage', 'edit', 'download', 'delete'
              if current_user.nil?
                flash[:error] = "You are not authorized to #{action} this #{name.humanize}, you may need to login first."
              else
                flash[:error] = "You are not authorized to #{action} this #{name.humanize}."
              end
              redirect_to(eval("#{self.controller_name.singularize}_path(#{object.id})"))
            else
              render :template => "general/landing_page_for_hidden_item", :locals => {:item => object}, :status => :forbidden
          end
        end
        format.rdf { render :text => "You may not #{action} #{name}:#{params[:id]}", :status => :forbidden }
        format.xml { render :text => "You may not #{action} #{name}:#{params[:id]}", :status => :forbidden }
        format.json { render :text => "You may not #{action} #{name}:#{params[:id]}", :status => :forbidden }
      end
      return false
    end
  end

  def auth_to_create
    unless self.controller_name.classify.constantize.can_create?
      error("You do not have permission", "No permission")
      return false
    end
  end

  def render_not_found_error

    respond_to do |format|
      format.html do
        User.with_current_user current_user do
          render :template => "general/landing_page_for_not_found_item", :status => :not_found
        end
      end

      format.rdf { render  :text=>"Not found",:status => :not_found }
      format.xml { render  :text=>"<error>404 Not found</error>",:status => :not_found }
      format.json { render :text=>"Not found", :status => :not_found }
    end
    false
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
    #FIXME: why is needed to wrap in this block when the around filter already does ?
    User.with_current_user current_user do
      controller_name = self.controller_name.downcase
      action = self.action_name.downcase

      object = object_for_request

      object=current_user if controller_name=="sessions" #logging in and out is a special case

      #don't log if the object is not valid or has not been saved, as this will a validation error on update or create
      return if object_invalid_or_unsaved?(object)

      case controller_name
        when "sessions"
          if ["create", "destroy"].include?(action)
            ActivityLog.create(:action => action,
                               :culprit => current_user,
                               :controller_name => controller_name,
                               :activity_loggable => object,
                               :user_agent => request.env["HTTP_USER_AGENT"])
          end
        when "sweeps", "runs"
          if ["show", "update", "destroy", "download"].include?(action)
            ref = object.projects.first
          elsif action == "create"
            ref = object.workflow
          end

          check_log_exists(action, controller_name, object)
          ActivityLog.create(:action => action,
                             :culprit => current_user,
                             :referenced => ref,
                             :controller_name => controller_name,
                             :activity_loggable => object,
                             :data => object.title,
                             :user_agent => request.env["HTTP_USER_AGENT"])
          break
        when *Seek::Util.authorized_types.map { |t| t.name.underscore.pluralize.split('/').last } # TODO: Find a nicer way of doing this...
          action = "create" if action == "upload_for_tool"
          action = "update" if action == "new_version"
          action = "inline_view" if action == "explore"
          if ["show", "create", "update", "destroy", "download", "inline_view"].include?(action)
            check_log_exists(action, controller_name, object)
            ActivityLog.create(:action => action,
                               :culprit => current_user,
                               :referenced => object.projects.first,
                               :controller_name => controller_name,
                               :activity_loggable => object,
                               :data => object.title,
                               :user_agent => request.env["HTTP_USER_AGENT"])
          end
        when "people","projects","institutions"
          if ["show", "create", "update", "destroy"].include?(action)
            ActivityLog.create(:action => action,
                               :culprit => current_user,
                               :controller_name => controller_name,
                               :activity_loggable => object,
                               :data => object.title,
                               :user_agent => request.env["HTTP_USER_AGENT"])
          end
        when "search"
          if action=="index"
            ActivityLog.create(:action => "index",
                               :culprit => current_user,
                               :controller_name => controller_name,
                               :user_agent => request.env["HTTP_USER_AGENT"],
                               :data => {:search_query => object, :result_count => @results.count})
          end
        when "content_blobs"
          action = "inline_view" if action=="view_content"
          if action=="inline_view" || (action=="download" && params['intent'].to_s != 'inline_view')
            activity_loggable = object.asset
            ActivityLog.create(:action => action,
                               :culprit => current_user,
                               :referenced => object,
                               :controller_name => controller_name,
                               :activity_loggable => activity_loggable,
                               :user_agent => request.env["HTTP_USER_AGENT"],
                               :data => activity_loggable.title)
          end
      end

      expire_activity_fragment_cache(controller_name, action)
    end
  end

  def object_invalid_or_unsaved?(object)
    object.nil? || (object.respond_to?('new_record?') && object.new_record?) || (object.respond_to?('errors') && !object.errors.empty?)
  end

  #determines and returns the object related to controller, e.g. @data_file
  def object_for_request
    c = controller_name.downcase

    eval('@' + c.singularize)
  end

  def expire_activity_fragment_cache(controller,action)
    if action!="show"
      @@auth_types ||=  Seek::Util.authorized_types.collect{|t| t.name.underscore.pluralize}
      if action=="download"
        expire_download_activity
      elsif action=="create" && controller!="sessions"
        expire_create_activity
      elsif action=="destroy" && controller!="sessions"
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

  #Strips any unexpected filter, which protects us from shennanigans like params[:filter] => {:destroy => 'This will destroy your data'}
  def strip_unpermitted_filters(filters)
    #placed this in a separate method so that other controllers could override it if necessary
    permitted = Seek::Util.persistent_classes.select {|c| c.respond_to? :find_by_id}.map {|c| c.name.underscore}
    filters.select{ |filter| permitted.include?(filter.to_s)}
  end

  def apply_filters(resources)
    filters = params[:filter] || {}

    #translate params that are send as an _id, like project_id=12 - which will usually be a consequence of nested routing
    params.keys.each do |key|
      if (key.end_with?("_id"))
        filters[key.gsub("_id", "")]=params[key]
      end
    end

    filters = strip_unpermitted_filters(filters)

    if filters.size>0
      params[:page]||="all"
      params[:filtered]=true
    end

    resources.select do |res|
      filters.all? do |filter, value|
        filter = filter.to_s
        klass = filter.camelize.constantize
        value = klass.find value.to_i

        detect_for_filter(filter, res, value)
      end
    end
  end

  def detect_for_filter(filter, resource, value)
    case
      when resource.respond_to?(filter.pluralize)
        resource.send(filter.pluralize).include? value
      when resource.respond_to?("related_#{filter.pluralize}")
        resource.send("related_#{filter.pluralize}").include?(value)
      when resource.respond_to?(filter)
        resource.send(filter) == value
      else
        false
    end
  end

  #checks if a captcha has been filled out correctly, if enabled, and returns false if not
  def check_captcha
    if Seek::Config.recaptcha_setup?
      verify_recaptcha
    else
      true
    end
  end

  def append_info_to_payload(payload)
    super
    payload[:user_agent] = request.user_agent
  end


  def log_extra_exception_data
      request.env["exception_notifier.exception_data"] = {
          :current_logged_in_user=>current_user
      }
  end

end



