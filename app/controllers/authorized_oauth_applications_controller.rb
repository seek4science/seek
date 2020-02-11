class AuthorizedOauthApplicationsController < Doorkeeper::AuthorizedApplicationsController
  before_action :check_user
  before_action :assign_person

  include Seek::BreadCrumbs

  private

  def check_user
    unless User.logged_in_and_member? || admin_logged_in?
      flash[:error] = 'This page is only available to members.'
      redirect_to root_path
    end
  end

  def assign_person
    @parent_resource = current_user&.person
  end
end
