# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  
  
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
  
  if ACTIVITY_LOG_ENABLED
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
    if ACTIVATION_REQUIRED && current_user && !current_user.active?
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
    unless defined? TYPE_MANAGERS
      error("Type management disabled", "...")
      return false
    end
    
    case TYPE_MANAGERS
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
    EMAIL_ENABLED    
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
    
    #don't log if the object is not valid, as this will a validation error on update or create
    return if object.nil? || (object.respond_to?("errors") && !object.errors.empty?)        
    
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
      when "data_files","models","sops","publications"
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
  
  def apply_filters(resources)
    set = resources
    unless params[:filter].blank? || (params[:filter][:project].blank? && params[:filter][:assay].blank? &&
      params[:filter][:study].blank? && params[:filter][:investigation].blank? && params[:filter][:person].blank?)
      set = resources.select do |res|
        pass = true
        unless params[:filter][:project].blank?
          if res.class.name == "Person" || res.class.name == "Institution"
            pass = pass && (res.projects.include?(Project.find_by_id(params[:filter][:project].to_i)))
          else
            pass = pass && (res.project.id == params[:filter][:project].to_i)            
          end
        end        
        unless params[:filter][:study].blank?
          if res.class.name == "Assay"
            pass = pass && (res.study_id == params[:filter][:study].to_i)
          else
            pass = pass && (res.assays.collect{|a| a.study_id}.include?(params[:filter][:study].to_i))
          end
        end
        unless params[:filter][:investigation].blank?
          if res.class.name == "Study" || res.class.name == "Assay"
            pass = pass && (res.investigation.id == params[:filter][:investigation].to_i)
          else
            pass = pass && (res.assays.collect{|a| a.study.investigation_id}.include?(params[:filter][:investigation].to_i))
          end
        end
        unless params[:filter][:assay].blank?
          pass = pass && (res.assay_ids.include?(params[:filter][:assay].to_i))
        end
        unless params[:filter][:person].blank?
          if (res.respond_to?("creators") && res.respond_to?("contributor")) #an asset that acts_as_resource
            #succeeds if and/or the creators contains the person, or the contributor is the person
            pass = pass && (res.creators.include?(Person.find_by_id(params[:filter][:person].to_i)) || (!res.contributor.nil? && res.contributor.person.id == params[:filter][:person].to_i))
          end          
          if (res.respond_to?("owner")) #assays
            pass = pass && (!res.owner.nil? && res.owner.id == params[:filter][:person].to_i)
          end
        end
        pass
      end
    end
    set
  end
  
end
