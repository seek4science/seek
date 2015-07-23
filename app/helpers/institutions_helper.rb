module InstitutionsHelper
  def can_create_institutions?
    User.admin_or_project_administrator_logged_in?
  end
end
