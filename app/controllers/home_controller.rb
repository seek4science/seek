class HomeController < ApplicationController
  
  before_filter :login_required  
  
  layout :select_layout
  
  def index
    respond_to do |format|
      format.html # index.html.erb      
    end
  end

  def faq
    respond_to do |format|
      format.html 
    end
  end
  
  def select_layout
    if logged_in?
      return 'main'
    else
      return 'logged_out'
    end
  end

  def feedback
    respond_to do |format|
      format.html
    end
  end

  def send_feedback
    subject=params[:subject]
    anon=params[:anon]
    details=params[:details]
    
    anon=anon=="true"

    puts "Anon = #{anon}"

    if subject.nil? or details.nil?
      flash[:error]="You must provide a Subject and details"
      render :action=>:feedback
    else
      if (Seek::ApplicationConfiguration.email_enabled)
        Mailer.deliver_feedback(current_user,subject,details,anon,base_host)
      end
      flash[:notice]="Your feedback has been delivered. Thank You."
      redirect_to root_path
    end
  end

  private

  RECENT_SIZE=3

 

  def classify_for_tabs result_collection
    #FIXME: this is duplicated in application_helper - but of course you can't call that from within controller
    results={}

    result_collection.each do |res|
      results[res.class.name] = [] unless results[res.class.name]
      results[res.class.name] << res
    end

    return results
  end

end
