class HomesController < ApplicationController
  helper HumanDiseasesHelper

  before_action :redirect_to_sign_up_when_no_user
  before_action :login_required, only: %i[feedback send_feedback]

  respond_to :html, only: [:index]

  def index
    respond_with do |format|
      format.html
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
end
