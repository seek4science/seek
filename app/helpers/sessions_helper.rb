module SessionsHelper
  LOGIN_STRATEGIES = %i[password elixir_aai ldap github oidc].freeze

  # strategies that take the user straight to an external provider, with no form to fill in first
  REDIRECTING_LOGIN_STRATEGIES = %i[elixir_aai github oidc].freeze

  # a person can be logged in but not fully registered during
  # the registration process whilst selecting or creating a profile
  def logged_in_and_registered?
    User.logged_in_and_registered?
  end

  # returns true if there is somebody logged in and they are an admin
  def admin_logged_in?
    User.admin_logged_in?
  end

  def detect_default_login_strategy
    available_login_strategies.first&.to_s
  end

  # the login strategies currently available, in order of preference
  def available_login_strategies
    LOGIN_STRATEGIES.select do |strategy|
      strategy == :password ? show_standard_password_login? : send("show_#{strategy}_login?")
    end
  end

  # the only way to log in, when that is a provider the user can be sent straight to
  def sole_redirecting_login_strategy
    strategies = available_login_strategies
    strategies.first if strategies.one? && REDIRECTING_LOGIN_STRATEGIES.include?(strategies.first)
  end

  # the provider to send the user straight to, skipping the login page altogether.
  # the strategy and error checks stop a failed login bouncing straight back to the provider.
  def auto_login_strategy
    return if params[:strategy].present? || flash[:error].present?

    sole_redirecting_login_strategy
  end

  # returns true if there is somebody logged in and they are an project manager
  def project_administrator_logged_in?
    User.project_administrator_logged_in?
  end

  def programme_administrator_logged_in?
    User.programme_administrator_logged_in?
  end

  def admin_or_programme_administrator_logged_in?
    admin_logged_in? || programme_administrator_logged_in?
  end

  def admin_or_project_administrator_logged_in?
    admin_logged_in? || project_administrator_logged_in?
  end

  # returns true if there is somebody logged in and they are member of a project
  def logged_in_and_member?
    User.logged_in_and_member?
  end

  def show_standard_password_login?
    # always show if omniauth options aren't available, regardless of standard_login_enabled setting
    params[:show_standard_login].present? || Seek::Config.standard_login_enabled || !show_omniauth_login?
  end

  def show_omniauth_login?
    Seek::Config.omniauth_enabled && Seek::Config.omniauth_providers.any?
  end

  def show_elixir_aai_login?
    Seek::Config.omniauth_elixir_aai_enabled
  end

  def show_ldap_login?
    Seek::Config.omniauth_ldap_enabled
  end

  def show_github_login?
    Seek::Config.omniauth_github_enabled
  end

  def show_oidc_login?
    Seek::Config.omniauth_oidc_enabled
  end

  def omniauth_method_name(key)
    name = nil
    name = Seek::Config.omniauth_oidc_name if key == :oidc
    name = t("login.#{key}") if name.blank?
    name
  end

  def oidc_login_button(original_path, text = "Sign in with #{Seek::Config.omniauth_oidc_name}", disabled = false)
    link = omniauth_authorize_path(:oidc, state: "return_to:#{original_path}")
    if Seek::Config.omniauth_oidc_image_id && (avatar = Avatar.find_by_id(Seek::Config.omniauth_oidc_image_id))
      link_to(image_tag(avatar.public_asset_url, alt: text), link, name: 'commit', disabled: disabled, method: :post)
    else
      button_link_to(text, 'lock', link, name: 'commit', disabled: disabled, method: :post)
    end
  end

  def oidc_register_button(disabled)
    oidc_login_button('/', "Register with #{Seek::Config.omniauth_oidc_name}", disabled)
  end
end
