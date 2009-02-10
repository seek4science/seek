# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  
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
      error("Activation of this account it required for gaining full access","Activation required?")      
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
  end

  def logout_user
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    session[:user_id]=nil
  end
  
  private

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
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :password
end
