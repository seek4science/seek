class HomeController < ApplicationController


  before_filter :redirect_to_sign_up_when_no_user


  def index
    @scale = Scale.find_by_title(params[:scale_type])
    #@scale ||= Scale.find_by_title('organism') #temporary to avoid expense of dealing with every object
    #@scale = nil if params[:scale_type] == 'all'
    @scaled_objects = @scale ? @scale.scalings.collect(&:scalable).compact.uniq : everything

    respond_to do |format|
      format.html # index.html.erb      
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

  def send_feedback
    @subject=params[:subject]
    @anon=params[:anon]
    @details=params[:details]
    
    @anon=@anon=="true"

    if @anon.nil? or @anon.nil?
      flash[:error]="You must provide a Subject and details"
      render :action=>:feedback
    else
      if verify_recaptcha && Seek::Config.email_enabled
        Mailer.deliver_feedback(current_user,@subject,@details,@anon,base_host)
        flash[:notice]="Your feedback has been delivered. Thank You."
        redirect_to root_path
      else
        flash[:error] = "Your word verification failed to be validated. Please try again."
        flash[:error] = "SEEK email functionality is not enabled yet" unless Seek::Config.email_enabled
        render :action=>:feedback
      end
    end
  end

  def redirect_to_sign_up_when_no_user
    if User.count == 0
      redirect_to :controller => 'users', :action => 'new'
    end
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

  private

  RECENT_SIZE=3

  def everything
    Seek::Util.user_creatable_types.inject([]) do |items, klass|
      items + klass.all
    end
  end

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
