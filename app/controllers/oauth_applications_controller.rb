class OauthApplicationsController < Doorkeeper::ApplicationsController
  before_action :check_user

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

  def add_breadcrumbs
    add_breadcrumb 'Home', root_path
    add_index_breadcrumb 'people'
    add_show_breadcrumb current_user&.person
    add_index_breadcrumb 'oauth_applications'
    add_breadcrumb 'New' if action_name == 'new'
    add_breadcrumb @application.name, oauth_application_path(@application) if defined? @application
    add_breadcrumb 'Edit' if action_name == 'edit'
  end

  def application_params
    params.require(:doorkeeper_application)
        .permit(:name, :redirect_uri, :scopes, :confidential, scopes: [])
  end
end
