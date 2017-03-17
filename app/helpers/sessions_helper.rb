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
end
