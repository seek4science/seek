class ApiTokensController < ApplicationController
  before_action :find_and_check_user

  include Seek::BreadCrumbs

  skip_before_action :add_breadcrumbs, only: [:destroy]

  def index
    @api_tokens = @user.api_tokens.order(created_at: :desc)

    respond_to do |format|
      format.html
    end
  end

  def create
    @api_token = @user.api_tokens.create(api_token_params)

    respond_to do |format|
      format.html
    end
  end

  def destroy
    @api_token = @user.api_tokens.find(params[:id])

    @api_token.destroy

    redirect_to user_api_tokens_path(@user)
  end

  private

  def api_token_params
    params.require(:api_token).permit(:title)
  end

  def find_and_check_user
    @user = User.find(params[:user_id])
    @parent_resource = @user&.person

    if current_user != @user
      error("User not found (id not authorized)", "is invalid (not owner)")
      false
    end
  end
end
