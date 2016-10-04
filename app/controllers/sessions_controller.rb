# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController

  before_filter :redirect_to_sign_up_when_no_user,:only=>:new
  skip_before_filter :restrict_guest_user
  skip_before_filter :project_membership_required
  skip_before_filter :profile_for_login_required,:only=>[:new,:destroy]
  skip_before_filter :partially_registered?,:only=>[:create,:new]
  prepend_before_filter :strip_root_for_xml_requests

  # render new.html.erb
  def new
    
  end

  def index
    redirect_to root_path
  end

  def show
    redirect_to root_path
  end

  def create
    # authentication through omniauth?
    if Seek::Config.omniauth_enabled && request.env.has_key?('omniauth.auth')
      create_omniauth(request.env['omniauth.auth'])
    else
      password_authentication
    end
  end

  def destroy
    logout_user
    flash[:notice] = "You have been logged out."

    begin
      if request.env['HTTP_REFERER'].try(:normalize_trailing_slash) == search_url.normalize_trailing_slash
        redirect_to :root
      else
        redirect_back
      end
    rescue RedirectBackError
      redirect :controller => :homes, :action => :index
    end
  end

  protected

  def password_authentication
    if @user = User.authenticate(params[:login], params[:password])
      check_login
    else
      failed_login "Invalid username/password. Have you <b> #{view_context.link_to "forgotten your password?", main_app.forgot_password_url }</b>".html_safe
    end  
  end

  private

  def check_login
    session[:user_id] = @user.id
    if !@user.registration_complete?
      flash[:notice] = "You have successfully registered your account, but you need to create a profile"
      redirect_to(register_people_path)
    elsif !@user.active?
      failed_login "You still need to activate your account. A validation email should have been sent to you."
    else
      successful_login
    end
  end
  
  def successful_login
    self.current_user = @user
    flash[:notice] = "You have successfully logged in, #{@user.display_name}."
    if params[:remember_me] == "on"
      @user.remember_me unless @user.remember_token?
      cookies[:auth_token] = { :value => @user.remember_token , :expires => @user.remember_token_expires_at }
    end
    respond_to do |format|
      return_to_url = determine_return_url_after_login
      format.html do
        is_search = return_to_url && return_to_url.normalize_trailing_slash == search_url.normalize_trailing_slash
        default_url = is_search ? root_url : return_to_url || root_url
        redirect_back_or_default(default_url)
      end
      format.xml {session[:xml_login] = true; head :ok }
    end
    clear_return_to
  end

  def determine_return_url_after_login
    if !params[:called_from].blank? && !params[:called_from][:url].blank?
      return_to_url = params[:called_from][:url]
    elsif !params[:called_from].blank? && params[:called_from][:controller] != "sessions"
      if params[:called_from][:id].blank?
        return_to_url = url_for(:controller => params[:called_from][:controller], :action => params[:called_from][:action])
      else
        return_to_url = url_for(:controller => params[:called_from][:controller], :action => params[:called_from][:action], :id => params[:called_from][:id])
      end
    else
        return_to_url = session[:return_to] || request.env['HTTP_REFERER']
    end
    return_to_url
  end

  def failed_login(message)
    logout_user
    flash[:error] = message
    respond_to do |format|
      return_to = params[:called_from] ? params[:called_from][:url] : nil
      format.html { redirect_to(login_path(:return_to=>return_to)) }
      format.xml { head :not_found }
    end
  end

  def create_omniauth(auth)
    require 'securerandom' #to set the seek user password to something random when the user is created

    # info contains username, first_ and last_name and email
    info = auth['info']
    
    # check if there is a user with that username as login
    user_by_omniauth = User.find_by_login( info['nickname'])
    if user_by_omniauth
      @user = user_by_omniauth
      check_login
    # there is no such user, should we not create the user?
    elsif !Seek::Config.omniauth_user_create
      failed_login "the authenticated user: #{info['nickname']} cannot be found"
    else
      # create the user from the omniauth info
      @user = User.create({:login => info['nickname']})
      # some random password, since authentication should happen through omniauth in the future
      @user.password              = SecureRandom.hex
      @user.password_confirmation = @user.password
      # try to save
      if !@user.save
        failed_login "Cannot create a new user: #{info['nickname']}"
      else
        # should we activate the user?
        @user.activate if Seek::Config.omniauth_user_activate
        # when user was saved successfully, also create the Profile and save with the user
        person = Person.create(auth['info'].slice(:first_name, :last_name, :email))
        person.user = @user
        person.save
        check_login
      end
    end
  end

end
