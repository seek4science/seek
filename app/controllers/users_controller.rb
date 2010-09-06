class UsersController < ApplicationController
  
  layout "logged_out", :except=>[:edit]
    
  before_filter :is_current_user_auth, :only=>[:edit, :update]  
  before_filter :is_user_admin_auth, :only => [:impersonate]
  
  # render new.rhtml
  def new
    @user=User.new
    
  end

  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @user = User.new(params[:user])

    #first user is automatically set as an admin user
    @user.is_admin=true if User.count == 0
    
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

  def reset_password
    user = User.find_by_reset_password_code(params[:reset_code])

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
          format.html { redirect_to(:controller => "session", :action => "new") }
        end
      else
        flash[:error] = "Invalid password reset code"
        format.html { redirect_to(:controller => "session", :action => "new") }
      end
    end 
  end

  def forgot_password    
    if request.get?
      # forgot_password.rhtml
    elsif request.post?      
      user = User.find_by_login(params[:login])

      respond_to do |format|
        if user && user.person && !user.person.email.blank?
          user.reset_password_code_until = 1.day.from_now
          user.reset_password_code =  Digest::SHA1.hexdigest( "#{user.email}#{Time.now.to_s.split(//).sort_by {rand}.join}" )
          user.save!
          Mailer.deliver_forgot_password(user, base_host)
          flash[:notice] = "Instructions on how to reset your password have been sent to #{user.person.email}"
          format.html { render :action => "forgot_password" }
        else
          flash[:error] = "Invalid login: #{params[:login]}" if !user
          flash[:error] = "Unable to send you an email, as this information isn't available for #{params[:login]}" if user && (!user.person || user.person.email.blank?)
          format.html { render :action => "forgot_password" }
        end
      end
    end
  end

  
  def edit
    @user = User.find(params[:id])
    render :action=>:edit, :layout=>"main"
  end
  
  def update    
    @user = User.find(params[:id])
    
    person=Person.find(params[:user][:person_id]) unless (params[:user][:person_id]).nil?        
    
    @user.person=person if !person.nil?
    
    @user.attributes=params[:user]

    if (!person.nil? && person.is_pal?)
      @user.person.can_edit_projects=true
      @user.person.can_edit_institutions=true
    end

    respond_to do |format|
      
      if @user.save
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
        format.html { render :action => 'edit' }
      end
    end
    
  end

  def activation_required
    
  end
  
  def impersonate
    user = User.find(params[:id])
    if user
      self.current_user = user
    end
    
    redirect_to :controller => 'home', :action => 'index'
  end

end
