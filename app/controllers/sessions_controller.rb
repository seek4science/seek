# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController

  before_filter :signup_admin_if_not_users,:only=>:new
  skip_before_filter :project_membership_required
  skip_before_filter :profile_for_login_required,:only=>[:new,:destroy]
  
  # render new.rhtml
  def new
    
  end

  def auto_openid
    create
  end

  def index    
    redirect_to login_url
  end

  def show
    redirect_to login_url
  end

  def create   
    if using_open_id?
      open_id_authentication
    else      
      password_authentication
    end   
  end

  def destroy    
    logout_user
    flash[:notice] = "You have been logged out."
    redirect_back
  end

  protected
  
  def open_id_authentication    
    authenticate_with_open_id do |result, identity_url|
      if result.successful?
        if @user = User.find_by_openid(identity_url)          
          check_login
        else
          failed_login "Sorry, no user by that identity URL exists (#{identity_url})"
        end
      else
        failed_login result.message
      end
    end
  end
  
  def password_authentication
    if @user = User.authenticate(params[:login], params[:password])
      check_login
    else
      failed_login "Invalid username/password."
    end  
  end

  private
  
  def check_login    
    session[:user_id] = @user.id
    if @user.person.nil?
      flash[:notice] = "You have successfully registered your account, but now must select a profile, or create your own."
      redirect_to(select_people_path)
	  elsif !@user.active?
      failed_login "You still need to activate your account. You should have been sent a validation email."
    #elsif @user.person && !@user.is_admin? && @user.person.projects.empty?
      #failed_login "You have not yet been assigned to a project by an administrator."
    else      
      successful_login
    end   
  end
  
  def successful_login
    self.current_user = @user    
    if params[:remember_me] == "on"
      @user.remember_me unless @user.remember_token?
      cookies[:auth_token] = { :value => @user.remember_token , :expires => @user.remember_token_expires_at }
    end
    
    respond_to do |format|
      if !params[:called_from].blank? && params[:called_from][:controller] != "sessions"
        unless params[:called_from][:id].blank?
          return_to_url = url_for(:controller => params[:called_from][:controller], :action => params[:called_from][:action], :id => params[:called_from][:id])
        else
          return_to_url = url_for(:controller => params[:called_from][:controller], :action => params[:called_from][:action])
        end
      else
        unless session[:return_to] and !session[:return_to].empty?
          return_to_url = request.env['HTTP_REFERER']
        else
          return_to_url = session[:return_to]
        end
      end
      
      format.html { return_to_url.nil? || (return_to_url && URI.parse(return_to_url).path == root_url) ? redirect_to(root_url) : redirect_to(return_to_url) }
    end
  end

  def failed_login(message)
    logout_user
    flash[:error] = message
    redirect_to(:root)
  end

  #will initiate creating an initial admin user if no users are present
  def signup_admin_if_not_users    
    redirect_to :signup if User.count==0
  end  
end