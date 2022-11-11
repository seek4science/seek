class HomesController < ApplicationController
  helper HumanDiseasesHelper

  before_action :redirect_to_sign_up_when_no_user
  before_action :login_required, only: %i[feedback send_feedback create_or_join_project report_issue]
  before_action :redirect_to_create_or_join_if_no_member, only: %i[index]
  after_action :fair_signposting, only: [:index]

  def index
    respond_to do |format|
      format.html
      format.jsonld do
        resource = determine_resource_for_schema_ld
        render json: Seek::BioSchema::Serializer.new(resource).json_representation, adapter: :attributes
      end
    end
  end

  def faq
    respond_to do |format|
      format.html
    end
  end

  def feedback
    respond_to do |format|
      format.html
    end
  end

  def report_issue
    respond_to do |format|
      format.html
    end
  end

  def isa_colours
    respond_to do |format|
      format.html
    end
  end

  def send_feedback
    @subject = params[:subject]
    @anon = params[:anon] == 'true'
    @details = params[:details]

    if validate_feedback
      Mailer.feedback(current_user, @subject, @details, @anon).deliver_later
      flash[:notice] = 'Your feedback has been delivered. Thank You.'
      redirect_to root_path
    else
      render action: :feedback
    end
  end

  def validate_feedback
    if @details.blank? || @subject.blank?
      msg = 'You must provide a Subject and details'
    elsif !Seek::Config.email_enabled
      msg = 'SEEK email functionality is not enabled yet'
    elsif !check_captcha
      msg = 'Your word verification failed to be validated. Please try again.'
    else
      return true
    end
    flash.now[:error] = msg
    false
  end

  def recent_changes
    respond_to do |format|
      format.html
    end
  end

  def seek_intro_demo
    respond_to do |format|
      format.html
    end
  end

  def redirect_to_create_or_join_if_no_member
    if User.logged_in? && !User.logged_in_and_member?
      redirect_to create_or_join_project_home_path
    end
  end

  private

  def fair_signposting
    @fair_signposting_links = [[root_url, { rel: :describedby, type: :jsonld }]]
  end
end
