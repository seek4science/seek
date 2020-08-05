class ProgrammesController < ApplicationController
  include Seek::IndexPager
  include Seek::DestroyHandling
  include ApiHelper

  before_action :programmes_enabled?
  before_action :login_required, except: [:show, :index]
  before_action :find_and_authorize_requested_item, only: [:edit, :update, :destroy, :storage_report]
  before_action :find_requested_item, only: [:show, :admin,:activation_review,:accept_activation,:reject_activation,:reject_activation_confirmation]
  before_action :find_assets, only: [:index]
  before_action :is_user_admin_auth, only: [:activation_review, :accept_activation,:reject_activation,:reject_activation_confirmation,:awaiting_activation]
  before_action :can_activate?, only: [:activation_review, :accept_activation,:reject_activation,:reject_activation_confirmation]
  before_action :inactive_view_allowed?, only: [:show]


  skip_before_action :project_membership_required

  include Seek::BreadCrumbs

  include Seek::IsaGraphExtensions

  respond_to :html, :json

  api_actions :index, :show, :create, :update, :destroy

  def create
    @programme = Programme.new(programme_params)

    respond_to do |format|
      if @programme.save
        flash[:notice] = "The #{t('programme').capitalize} was successfully created."

        # current person becomes the programme administrator, unless they are logged in
        # also activation email is sent
        unless User.admin_logged_in?
          current_person.is_programme_administrator = true, @programme
          disable_authorization_checks { current_person.save! }
          if Seek::Config.email_enabled
            Mailer.delay.programme_activation_required(@programme,current_person)
          end
        end
        format.html {respond_with(@programme)}
        format.json {render json: @programme, include: [params[:include]]}
      else
        format.html { render action: 'new' }
        format.json { render json: json_api_errors(@programme), status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @programme.update_attributes(programme_params)
        flash[:notice] = "The #{t('programme').capitalize} was successfully updated"
        format.html { redirect_to(@programme) }
        format.xml { head :ok }
        format.json { render json: @programme, include: [params[:include]] }
      else
        format.html { render action: 'edit' }
        format.xml { render xml: @programme.errors, status: :unprocessable_entity }
        format.json { render json: json_api_errors(@programme), status: :unprocessable_entity }
      end
    end
  end

  def handle_administrators
    params[:programme][:administrator_ids] = params[:programme][:administrator_ids].split(',')
    prevent_removal_of_self_as_programme_administrator
  end

  # if the current person is the administrator, but not a system admin, they need to be added - they cannot remove themself.
  def prevent_removal_of_self_as_programme_administrator
    return if User.admin_logged_in?
    return unless @programme
    if current_person.is_programme_administrator?(@programme)
      params[:programme][:administrator_ids] << current_person.id.to_s
    end
  end

  def awaiting_activation
    @not_activated = Programme.not_activated
    @rejected = @not_activated.rejected
    @not_activated = @not_activated - @rejected
  end

  def edit
    respond_with(@programme)
  end

  def new
    @programme = Programme.new
    respond_with(@programme)
  end

  def show
    respond_with do |format|
      format.html
      format.json {render json: @programme, include: [params[:include]]}
      format.rdf { render template: 'rdf/show' }
    end
  end

  def accept_activation
    @programme.activate
    flash[:notice]="The #{t('programme')} has been activated"
    Mailer.delay.programme_activated(@programme) if Seek::Config.email_enabled
    redirect_to @programme
  end

  def reject_activation
    flash[:notice]="The #{t('programme')} has been rejected"
    @programme.update_attribute(:activation_rejection_reason,params[:programme][:activation_rejection_reason])
    Mailer.delay.programme_rejected(@programme,@programme.activation_rejection_reason) if Seek::Config.email_enabled
    redirect_to @programme
  end

  def storage_report
    respond_with do |format|
      format.html { render partial: 'programmes/storage_usage_content',
                           locals: { programme: @programme } }
    end
  end

  private

  #whether the item needs or can be activated, which affects steps around activation of rejection
  def can_activate?
    unless result=@programme.can_activate?
      error("The #{t('programme')} activation status cannot be changed. Maybe it is already activated or you are not an administrator", "cannot activate (not admin or already activated)")
    end
    result
  end

  #is the item inactive, and if so can the current person view it
  def inactive_view_allowed?
    return true if @programme.is_activated? || User.admin_logged_in?
    unless result=(User.logged_in_and_registered? && @programme.programme_administrators.include?(current_person))
      error("This programme is not activated and cannot be viewed", "cannot view (not activated)", :forbidden)
    end
    result
  end

  private

  def fetch_assets
    if User.admin_logged_in?
      @programmes = Programme.all
    elsif User.programme_administrator_logged_in?
      @programmes = Programme.activated | current_person.administered_programmes
    else
      @programmes = Programme.activated
    end
  end

  def programme_params
    handle_administrators if params[:programme][:administrator_ids] && !(params[:programme][:administrator_ids].is_a? Array)

    params.require(:programme).permit(:avatar_id, :description, :first_letter, :title, :uuid, :web_page,
                                      { project_ids: [] }, :funding_details, { administrator_ids: [] },
                                      :activation_rejection_reason, :funding_codes,
                                      :open_for_projects,
                                      discussion_links_attributes:[:id, :url, :label, :_destroy])
  end

end
