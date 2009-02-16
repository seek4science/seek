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
      @user.activate unless ACTIVATION_REQUIRED
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
      Mailer.deliver_welcome current_user, base_host
      flash[:notice] = "Signup complete!"
      redirect_to current_user.person
    else
      redirect_back_or_default('/')
    end
  end


  
  def edit
    @user = User.find(params[:id])
    render :action=>:edit, :layout=>"main"
  end
  
  def update

    @user = User.find(params[:id])
    person=Person.find(params[:user][:person_id]) unless (params[:user][:person_id]).nil?

    person_already_associcated=!person.user.nil?
    
    @user.person=person if !person.nil? && !person_already_associcated
    
    @user.attributes=params[:user]

    respond_to do |format|
      
      if @user.save && !person_already_associcated
        #user has associated himself with a person, so activation email can now be sent
        if !current_user.active?
          Mailer.deliver_signup(@user,base_host)
          flash[:notice]="An email has been sent to you to confirm your email address. You need to respond to this email before you can login"
          logout_user
          format.html { redirect_to :action=>"activation_required" }
        else
          flash[:notice]="Your account details have been updated"
          format.html { redirect_to person_path(@user.person) } 
        end        
      else
        flash[:error]="That person has already been associated with a user" if person_already_associcated
        format.html { render :action => 'edit' }
      end
    end
    
  end

  def activation_required
    
  end

end
