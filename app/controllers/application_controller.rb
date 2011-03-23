	# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  self.mod_porter_secret = PORTER_SECRET

  include ExceptionNotifiable 
  self.error_layout="errors" 
  self.silent_exceptions = []
  self.rails_error_classes = { 
    ActiveRecord::RecordNotFound => "404",
    ::ActionController::UnknownController => "406",
    ::ActionController::UnknownAction => "406",
    ::ActionController::RoutingError => "404",
    ::ActionView::MissingTemplate => "406",
    ::ActionView::TemplateError => "500"
  }
  local_addresses.clear

  exception_data :additional_exception_notifier_data

  if Seek::Config.activity_log_enabled
    after_filter :log_event
  end

  include AuthenticatedSystem
  
  helper :all
  
  layout "main"
  
  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'cfb59feef722633aaee5ee0fd816b5fb'
  
  def set_no_layout
    self.class.layout nil
  end
  
  def base_host
    request.host_with_port
  end 
  
  
  def self.fast_auto_complete_for(object, method, options = {})
    define_method("auto_complete_for_#{object}_#{method}") do
      render :json => object.to_s.camelize.constantize.find(:all).map(&method).to_json
    end
  end
  
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
      @user = User.find(params[:id], :conditions => ["id = ?", current_user.id])
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
    unless current_user.is_admin?
      error("Admin rights required", "is invalid (not admin)")
      return false
    end
    return true
  end
  
  def can_manage_announcements?
    return current_user.is_admin?
  end
  
  def logout_user
    current_user.forget_me if logged_in?
    cookies.delete :auth_token
    cookies.delete :open_id
    reset_session    
  end
  
  private
  
  def is_project_member
    
    if !Authorization.is_member?(current_user.person_id, nil, nil)
      flash[:error] = "Only members of known projects, institutions or work groups are allowed to create new content."
      redirect_to studies_path
    end
    
  end
  
  def pal_or_admin_required
    unless current_user.is_admin? || (!current_user.person.nil? && current_user.person.is_pal?)
      error("Admin or PAL rights required", "is invalid (not admin)")
      return false
    end
  end
  
  
  def check_allowed_to_manage_types
    unless Seek::Config.type_managers_enabled
      error("Type management disabled", "...")
      return false
    end
    
    case Seek::Config.type_managers
      when "admins"
      if current_user.is_admin? 
        return true
      else
        error("Admin rights required to manage types", "...")
        return false
      end
      when "pals"
      if current_user.is_admin? || current_user.person.is_pal? 
        return true
      else
        error("Admin or PAL rights required to manage types", "...")
        return false
      end
      when "users"
      return true        
      when "none"
      error("Type management disabled", "...")
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
    current_user && current_user.is_admin?
  end
  
  def email_enabled?
    Seek::Config.email_enabled
  end

  def find_and_auth
    begin
      name = self.controller_name.singularize
      action=action_name
      action = translate_action(action) if respond_to?(:translate_action)            

      object = name.camelize.constantize.find(params[:id])

      if Authorization.is_authorized?(action, nil, object, current_user)
        eval "@#{name} = object"
        params.delete :sharing unless object.can_manage?(current_user)
      else
        respond_to do |format|
          flash[:error] = "You are not authorized to perform this action"
          format.html { redirect_to eval "#{self.controller_name}_path" }
          #FIXME: this isn't the right response - should return with an unauthorized status code
          format.xml { redirect_to eval "#{self.controller_name}_path(:format=>'xml')" }
        end
        return false
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        flash[:error] = "Couldn't find the #{name.humanize} or you are not authorized to view it"
        format.html { redirect_to eval "#{self.controller_name}_path" }
      end
      return false
    end
  end
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password
  
  def log_event
    c = self.controller_name.downcase
    a = self.action_name.downcase
    
    object = eval("@"+c.singularize)
    
    object=current_user if c=="sessions" #logging in and out is a special case    
    
    #don't log if the object is not valid or has not been saved, as this will a validation error on update or create
    return if object.nil? || (object.respond_to?("new_record?") && object.new_record?) || (object.respond_to?("errors") && !object.errors.empty?)
    
    case c
      when "sessions"
      if ["create","destroy"].include?(a)
        ActivityLog.create(:action => a,
                   :culprit => current_user,                   
                   :controller_name=>c,
                   :activity_loggable => object)
      end
      when "investigations","studies","assays"
      if ["show","create","update","destroy"].include?(a)
        ActivityLog.create(:action => a,
                   :culprit => current_user,
                   :referenced => object.project,
                   :controller_name=>c,
                   :activity_loggable => object)
      end 
      when "data_files","models","sops","publications","events"
      if ["show","create","update","destroy","download"].include?(a)
        ActivityLog.create(:action => a,
                   :culprit => current_user,
                   :referenced => object.project,
                   :controller_name=>c,
                   :activity_loggable => object)
      end 
      when "people"
      if ["show","create","update","destroy"].include?(a)
        ActivityLog.create(:action => a,
                   :culprit => current_user,
                   :controller_name=>c,
                   :activity_loggable => object)      
      end 
      when "search"
      if a=="index"
        ActivityLog.create(:action => "index",
                   :culprit => current_user,
                   :controller_name=>c,
                   :data => {:search_query=>object,:result_count=>@results.count}) 
      end
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
        #then the general case
        when res.respond_to?(filter)                         then res.send(filter) == value
        when res.respond_to?(filter.pluralize)               then res.send(filter.pluralize).include? value
        #defaults to true, if a filter is irrelevant then it is silently ignored
        else true
        end
      end
    end
  end

  def additional_exception_notifier_data
    {
        :current_logged_in_user=>current_user
    }
  end
  
end
