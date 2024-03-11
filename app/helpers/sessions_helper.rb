module SessionsHelper
  # a person can be logged in but not fully registered during
  # the registration process whilst selecting or creating a profile
  def logged_in_and_registered?
    User.logged_in_and_registered?
  end

  # returns true if there is somebody logged in and they are an admin
  def admin_logged_in?
    User.admin_logged_in?
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

  def oidc_login_button(original_path)
    text = "Sign in with #{Seek::Config.omniauth_oidc_name}"
    link = omniauth_authorize_path(:oidc, state: "return_to:#{original_path}")
    if Seek::Config.omniauth_oidc_image_id && (avatar = Avatar.find_by_id(Seek::Config.omniauth_oidc_image_id))
      link_to(image_tag(avatar.public_asset_url, alt: text), link, method: :post)
    else
      button_link_to(text, 'lock', link, method: :post)
    end
  end
end
