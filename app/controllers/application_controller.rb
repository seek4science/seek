# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base


  if ENV['RAILS_ENV'] == "production"
    rescue_from ActiveRecord::RecordNotFound, ActionController::RoutingError, ActionController::UnknownController, ActionController::UnknownAction, :with => :render_404
    rescue_from NameError, RuntimeError, :with => :render_500
  end


  include AuthenticatedSystem

  helper :all # include all helpers, all the time
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

  def logout_user
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    session[:user_id]=nil
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

  #Custom error pages
  def render_500
    @title="We're sorry, but something went wrong (500)"
    render :template=>"errors/500", :layout=>"errors"
  end

  def render_404
    @title="The page you were looking for doesn't exist (404)"
    render :template=>"errors/404", :layout=>"errors"
  end

  def download_jerm_resource resource
      project=resource.project
      project.decrypt_credentials
      downloader=Jerm::DownloaderFactory.create project.name, project.site_username,project.site_password
      data_hash = downloader.get_remote_data resource.content_blob.url
      send_data data_hash[:data], :filename => data_hash[:filename] || resource.original_filename, :content_type => data_hash[:content_type] || resource.content_type, :disposition => 'attachment'
  end

  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password

end
