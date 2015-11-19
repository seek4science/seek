class UsersController < ApplicationController

  before_filter :is_current_user_auth, :only=>[:edit, :update]
  before_filter :is_user_admin_auth, :only => [:impersonate, :resend_activation_email, :destroy]

  skip_before_filter :restrict_guest_user
  skip_before_filter :project_membership_required

  skip_before_filter :partially_registered?,:only=>[:update,:cancel_registration]

  include Seek::AdminBulkAction
  
  # render new.rhtml
  def new
    @user = User.new
  end

  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with
    # request forgery protection.
    # uncomment at your own risk
    # reset_session

    @user = User.new(params[:user])
    @user.check_email_present=true
    check_registration

  end

  def cancel_registration
    user = current_user
    if user && !user.person
      logout_user
      user.destroy
    end
    redirect_to main_app.root_path
  end

  def activate
    self.current_user = params[:activation_code].blank? ? false : User.find_by_activation_code(params[:activation_code])
    if logged_in? && !current_user.active?
      current_user.activate      
      if (current_person.projects.empty? && User.count>1)
        Mailer.welcome_no_projects(current_user).deliver
        logout_user
        flash[:notice] = "Signup complete! However, you will need to wait for an administrator to associate you with your project(s) before you can login."        
        redirect_to main_app.root_path
      else
        Mailer.welcome(current_user).deliver
        flash[:notice] = "Signup complete!"
        redirect_to current_person
      end
    else
      redirect_back_or_default('/')
    end
  end

  def reset_password
    user = User.find_by_reset_password_code(params[:reset_code] || "")

    respond_to do |format|
      if user
        if user.reset_password_code_until && Time.now < user.reset_password_code_until
          user.reset_password_code = nil
          user.reset_password_code_until = nil
          if user.save
            self.current_user = user
            if logged_in?
              flash[:notice] = "You can change your password here"
              format.html { redirect_to(:action => "edit", :id => user.id) }
            else
              flash[:error] = "An unknown error has occurred. We are sorry for the inconvenience. You can request another password reset here."
              format.html { render :action => "forgot_password" }
            end
          end
        else
          flash[:error] = "Your password reset code has expired"
          format.html { redirect_to(main_app.root_path) }
        end
      else
        flash[:error] = "Invalid password reset code"
        format.html { redirect_to(main_app.root_path) }
      end
    end 
  end

  def forgot_password    
    if request.get?
      # forgot_password.rhtml
    elsif request.post?      
      user = User.find_by_login(params[:login]) || Person.where(email: params[:login]).first.try(:user)

      respond_to do |format|
        if user && user.person && !user.person.email.blank?
          user.reset_password

          user.save!
          Mailer.forgot_password(user).deliver if Seek::Config.email_enabled
          flash[:notice] = "Instructions on how to reset your password have been sent to #{user.person.email}"
          format.html { render :action => "forgot_password" }
        else
          flash[:error] = "Invalid login name/email: #{params[:login]}" if !user
          flash[:error] = "Unable to send you an email, as this information isn't available for #{params[:login]}" if user && (!user.person || user.person.email.blank?)
          format.html { render :action => "forgot_password" }
        end
      end
    end
  end

  
  def edit
    @user = User.find(params[:id])
    render :action=>:edit
  end
  
  def update    
    @user = User.find(params[:id])
    if @user==current_user && !@user.registration_complete? && (params[:user][:person_id]) && (params[:user][:email])
      person_id = params[:user][:person_id]
      email = params[:user][:email]
      person=Person.not_registered.detect do |person|
        person.id.to_s == person_id && person.email == email && person.user.nil?
      end
      @user.person=person
      do_auth_update = !person.nil?
    end

    if params[:user]
      [:id, :person_id,:email].each do |column_name|
        params[:user].delete(column_name)
      end
    end
    
    @user.attributes=params[:user]    

    respond_to do |format|
      if @user.save
        AuthLookupUpdateJob.new.add_items_to_queue(@user) if do_auth_update
        #user has associated himself with a person, so activation email can now be sent
        if !current_user.active?
          Mailer.signup(@user).deliver
          flash[:notice]="An email has been sent to you to confirm your email address. You need to respond to this email before you can login"
          logout_user
          format.html { redirect_to :action=>"activation_required" }
        else
          flash[:notice]="Your account details have been updated"
          format.html { redirect_to person_path(@user.person) } 
        end        
      else        
        format.html { render :action => 'edit' }
      end
    end
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy if @user && !@user.person
    respond_to do |format|
      format.html { redirect_back }
      format.xml { head :ok }
    end
  end

  def resend_activation_email
    user = User.find(params[:id])
    if user && user.person && !user.active?
      Mailer.signup(user).deliver
      flash[:notice]="An email has been sent to user: #{user.person.name}"
    else
      flash[:notice] = "No email sent. User was already activated."
    end

    redirect_back
  end

  def activation_required
    
  end
  
  def impersonate
    user = User.find(params[:id])
    if user
      self.current_user = user
    end
    
    redirect_to :controller => 'homes', :action => 'index'
  end

  protected
  
  private 
  
  def check_registration       
    if @user.save
      successful_registration
    else
      failed_registration @user.errors.full_messages.to_sentence
    end
  end
  
  def failed_registration(message)
    flash.now[:error] = message
    render :new
  end
  
  def successful_registration
    @user.activate unless activation_required?
    self.current_user = @user
    redirect_to(register_people_path(:email=>@user.email))
  end
  
  def activation_required?
    Seek::Config.activation_required_enabled && User.count>1
  end

end
