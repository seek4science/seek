class IdentitiesController < ApplicationController
  before_action :find_and_check_user

  include Seek::BreadCrumbs

  skip_before_action :add_breadcrumbs, only: :destroy

  def index
    @identities = @user.identities
  end

  def destroy
    @identity = @user.identities.find(params[:id])

    @identity.destroy
    flash[:notice] = "Unlinked #{t("login.#{@identity.provider}")} identity from your account."
    redirect_to user_identities_path(@user)
  end

  private

  def find_and_check_user
    @user = User.find(params[:user_id])
    @parent_resource = @user&.person

    if current_user != @user
      error("User not found (id not authorized)", "is invalid (not owner)")
      false
    end
  end
end
