class OauthApplicationsController < Doorkeeper::ApplicationsController
  before_action :check_user
  before_action :assign_person

  include Seek::BreadCrumbs

  layout Seek::Config.main_layout

  def index
    @applications = current_user.oauth_applications.ordered_by(:created_at)

    respond_to do |format|
      format.html
      format.json { head :no_content }
    end
  end

  def create
    @application = current_user.oauth_applications.build(application_params)

    if @application.save
      flash[:notice] = I18n.t(:notice, scope: %i[doorkeeper flash applications create])
      flash[:application_secret] = @application.plaintext_secret

      respond_to do |format|
        format.html { redirect_to oauth_application_url(@application) }
        format.json { render json: @application }
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.json do
          errors = @application.errors.full_messages

          render json: { errors: errors }, status: :unprocessable_entity
        end
      end
    end
  end

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
