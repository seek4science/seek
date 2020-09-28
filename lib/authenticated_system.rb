module AuthenticatedSystem
  protected
  # Returns true or false if the user is logged in.
  # Preloads @current_user with the user model if they're logged in.
  def logged_in?
    current_user && !current_user.guest?
  end

  # Accesses the current user from the session.
  # Future calls avoid the database because nil is not equal to false.
  def current_user
    if defined? @current_user
      @current_user
    else
      self.current_user = (user_from_session || user_from_doorkeeper  || user_from_basic_auth || user_from_cookie || user_from_api_token || User.guest)
    end
  end

  # Store the given user id in the session.
  def current_user=(new_user)
    session[:user_id] = new_user.try(:id)
    @current_user = new_user
  end

  def clear_current_user
    @current_user = nil
    remove_instance_variable(:@current_user)
  end

  # Check if the user is authorized
  #
  # Override this method in your controllers if you want to restrict access
  # to only a few actions or if you want to check if the user
  # has the correct rights.
  #
  # Example:
  #
  #  # only allow nonbobs
  #  def authorized?
  #    current_user.login != "bob"
  #  end
  def authorized?
    logged_in?
  end

  # Filter method to enforce a login requirement.
  #
  # To require logins for all actions, use this in your controllers:
  #
  #   before_action :login_required
  #
  # To require logins for specific actions, use this in your controllers:
  #
  #   before_action :login_required, :only => [ :edit, :update ]
  #
  # To skip this in a subclassed controller:
  #
  #   skip_before_action :login_required
  #
  def login_required
    unless authorized?
      flash[:error]="You need to be logged in"
      access_denied(main_app.login_path)
    end
  end

  # Redirect as appropriate when an access request fails.
  #
  # The default action is to redirect to the login screen.
  #
  # Override this method in your controllers if you want to have special
  # behavior in case the user is not authorized
  # to access the requested action.  For example, a popup window might
  # simply close itself.
  def access_denied(redirect_path = main_app.root_path)
    request.format = :html if request.env['HTTP_USER_AGENT'] =~ /msie/i

    respond_to do |format|
      format.html do
        store_return_to_location
        redirect_to redirect_path
      end
      format.any do
        request_http_basic_authentication 'Web Password'
      end
    end
  end

  # Store the URI of the current request in the session.
  #
  # We can return to this location by calling #redirect_back_or_default.
  def store_return_to_location
    session[:return_to] = request.fullpath
  end

  def clear_return_to
    session.delete(:return_to)
  end

  # Redirect to the URI stored by the most recent store_return_to_location call or
  # to the passed default.
  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    clear_return_to
  end

  # Inclusion hook to make #current_user and #logged_in?
  # available as ActionView helper methods.
  def self.included(base)
    base.send :helper_method, :current_user, :logged_in?
  end

  # Called from #current_user.  First attempt to login by the user id stored in the session.
  def user_from_session
    User.find_by_id(session[:user_id]) if session[:user_id]
  end

  # Called from #current_user.  Now, attempt to login by basic authentication information.
  def user_from_basic_auth
    authenticate_with_http_basic do |username, password|
      user = User.authenticate(username, password)
      sleep 2 if Rails.env.production? && (username.present? && !user) # Throttle incorrect login
      user
    end
  end

  # Called from #current_user.  Finaly, attempt to login by an expiring token in the cookie.
  def user_from_cookie
    return unless cookies[:auth_token]

    user = User.find_by_remember_token(cookies[:auth_token])
    if user&.remember_token?
      cookies[:auth_token] = { value: user.remember_token, expires: user.remember_token_expires_at }
      user
    end
  end

  def user_from_api_token
    authenticate_with_http_token do |api_token, _options|
      return unless api_token.length > 1

      user = User.from_api_token(api_token)
      sleep 2 if Rails.env.production? && !user # Throttle incorrect login
      user
    end
  end

  # Is the user authenticated through an OAuth application?
  def user_from_doorkeeper
    if doorkeeper_token&.accessible?
      User.find(doorkeeper_token.resource_owner_id)
    end
  end
end
