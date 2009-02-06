class UsersController < ApplicationController
  
  layout "logged_out", :except=>[:edit]
    
  before_filter :is_current_user_auth, :only=>[:edit, :update]
  
  # render new.rhtml
  def new
    @user=User.new
    @user.person=Person.new
  end

  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @user = User.new(params[:user])
    @user.person=Person.new(params[:person])
    
    @user.save
    
    if @user.errors.empty?
      self.current_user = @user
      redirect_to(select_people_path)
    else
      render :action => 'new'
    end
  end

  def activate
    self.current_user = params[:activation_code].blank? ? false : User.find_by_activation_code(params[:activation_code])
    if logged_in? && !current_user.active?
      current_user.activate
      flash[:notice] = "Signup complete!"
    end
    redirect_back_or_default('/')
  end
  
  def edit
    @user = User.find(params[:id])
    render :action=>:edit, :layout=>"main"
  end
  
  def update
    @user = User.find(params[:id])
    @user.person=Person.find(params[:user][:person_id]) unless (params[:user][:person_id]).nil?
    @user.attributes=params[:user]
    respond_to do |format|
      if @user.save
        #user has associated himself with a person, so activation email can now be sent
        unless (params[:user][:person_id]).nil?
          Mailer.deliver_signup(@user,base_host)
          flash[:notice]="An email has been sent to you to confirm your email address. You need to respond to this email before you can login"
          redirect_to :controller=>:session, :action=>:new
        else
          format.html { redirect_to person_path(@user.person) }
        end
      else
        format.html { render :action => 'edit' }
      end
    end
  end

end
