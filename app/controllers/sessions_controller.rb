require 'securerandom' # to set the seek user password to something random when the user is created

# This controller handles the login/logout function of the site.
class SessionsController < ApplicationController
  before_action :redirect_to_sign_up_when_no_user, only: :new
  skip_before_action :restrict_guest_user
  skip_before_action :project_membership_required
  skip_before_action :partially_registered?, only: %i[create new]
  prepend_before_action :strip_root_for_xml_requests

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
    auth = request.env['omniauth.auth'] # `omniauth.auth` comes from the omniauth rack middleware.
    # See: https://github.com/omniauth/omniauth/wiki/Auth-Hash-Schema for schema.
    if auth && Seek::Config.omniauth_enabled
      # This check is only necessary if the server has not been restarted after an omniauth option was disabled.
      # Should be handled by `config/initializers/seek_omniauth.rb`.
      provider_enabled = case auth.provider
                         when 'ldap'
                           Seek::Config.omniauth_ldap_enabled
                         when 'elixir_aai'
                           Seek::Config.omniauth_elixir_aai_enabled
                         else
                           true
                         end
      if provider_enabled
        omniauth_authentication(auth)
        return
      end
    end

    password_authentication
  end

  def omniauth_failure
    flash[:error] = "#{t("login.#{params[:strategy]}")} authentication failure (Invalid username/password?)"
    respond_to do |format|
      format.html { render :new }
    end
  end

  def destroy
    logout_user
    flash[:notice] = 'You have been logged out.'

    begin
      if request.env['HTTP_REFERER'].try(:normalize_trailing_slash) == search_url.normalize_trailing_slash
        redirect_to :root
      else
        redirect_back(fallback_location: root_path)
      end
    rescue RedirectBackError
      redirect controller: :homes, action: :index
    end
  end

  protected

  def password_authentication
    if @user = User.authenticate(params[:login], params[:password])
      check_login
    else
      failed_login "Invalid username/password. Have you <b> #{view_context.link_to 'forgotten your password?', main_app.forgot_password_path}</b>".html_safe
    end
  end

  private

  def check_login(success_notice = nil, person_params: {})
    session[:user_id] = @user.id
    if !@user.registration_complete?
      flash[:notice] = 'You have successfully registered your account, but you need to create a profile'
      redirect_to(register_people_path(person_params))
    elsif !@user.active?
      failed_login 'You still need to activate your account. A validation email should have been sent to you.'
    else
      successful_login(success_notice)
    end
  end

  def successful_login(notice = nil)
    self.current_user = @user

    flash[:notice] = notice || "You have successfully logged in, #{@user.display_name}."
    if params[:remember_me] == 'on'
      @user.remember_me unless @user.remember_token?
      cookies[:auth_token] = { value: @user.remember_token, expires: @user.remember_token_expires_at }
    end
    respond_to do |format|
      return_to_path = determine_return_path_after_login
      format.html do
        is_search = return_to_path&.normalize_trailing_slash == search_path.normalize_trailing_slash
        default_path = is_search ? root_path : return_to_path || root_path
        redirect_back_or_default(default_path)
      end
      format.xml { session[:xml_login] = true; head :ok }
    end
    clear_return_to
  end

  def determine_return_path_after_login
    if !params[:called_from].blank? && !params[:called_from][:path].blank?
      return_to_url = params[:called_from][:path]
    elsif !params[:called_from].blank? && params[:called_from][:controller] != 'sessions'
      if params[:called_from][:id].blank?
        return_to_url = url_for(controller: params[:called_from][:controller], action: params[:called_from][:action])
      else
        return_to_url = url_for(controller: params[:called_from][:controller], action: params[:called_from][:action], id: params[:called_from][:id])
      end
    elsif request.env.dig('omniauth.params', 'state')&.start_with?('return_to:')
      return_to_url = request.env['omniauth.params']['state'].match(/return_to:(.+)/)&.captures&.last
    else
      return_to_url = session[:return_to] || request.env['HTTP_REFERER']
    end

    begin
      URI.parse(return_to_url).path
    rescue
      root_path
    end
  end

  def failed_login(message)
    logout_user
    flash[:error] = message
    respond_to do |format|
      return_to = params[:called_from] ? params[:called_from][:path] : nil
      format.html { redirect_to(login_path(return_to: return_to)) }
      format.xml { head :not_found }
    end
  end

  def omniauth_authentication(auth)
    # Check if there is an existing identity for this provider/uid, or initialize a new one.
    @identity = Identity.from_omniauth(auth)

    if @identity.user # The identity has a user.
      @user = @identity.user
      check_login
    else # The identity does not have an associated user.
      # *** LEGACY SUPPORT ***
      if auth.provider.to_s == 'ldap' # If using LDAP, attempt to find user by login.
        @user = User.find_by_login(auth.info.nickname)
        if @user
          @identity.user = @user
          @identity.save! # Update identity so we don't have to do this again.
          check_login
          return
        end
      end

      if logged_in? # There is a user logged in, so link the identity to the current user.
        link_identity_to_user(auth)
      else # There is no user currently logged in.
        if Seek::Config.omniauth_user_create # Create a new user if allowed.
          create_user_from_omniauth(auth)
        else # If user creation is not allowed, too bad.
          failed_login "The authenticated user: #{auth.info.nickname} does not have a #{Seek::Config.instance_name} account."
        end
      end
    end
  end

  def link_identity_to_user(auth)
    @user = current_user
    @identity.user = @user
    @identity.save!
    flash[:notice] = "Successfully linked #{t("login.#{auth.provider}")} identity to your account."
    redirect_to user_identities_path(@user)
  end

  def create_user_from_omniauth(auth)
    @user = User.from_omniauth(auth)
    saved = nil
    @user.check_email_present = false
    disable_authorization_checks { saved = @user.save }
    if saved
      # should we activate the user?
      @user.activate if Seek::Config.omniauth_user_activate && !@user.active?
      @identity.user = @user
      @identity.save!
      person_params = auth.info.with_indifferent_access.slice(:first_name, :last_name, :email, :name)
      check_login(nil, person_params: person_params)
    else # An unexpected error occurred whilst saving the user.
      failed_login "Cannot create a new user: #{@user.errors.full_messages.join(', ')}."
    end
  end
end
