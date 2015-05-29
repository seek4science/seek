class UsersController < ApplicationController

  before_filter :is_current_user_auth, :only=>[:edit, :update]
  before_filter :is_user_admin_auth, :only => [:impersonate, :resend_activation_email, :destroy]

  skip_before_filter :restrict_guest_user
  skip_before_filter :project_membership_required
  skip_before_filter :profile_for_login_required,:only=>[:update,:cancel_registration]

  include Seek::AdminBulkAction
  
  # render new.rhtml
  def new
  end

  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    if using_open_id?
      open_id_authentication(params[:openid_identifier])
    else
      @user = User.new(:login => params[:login], :password => params[:password], :password_confirmation => params[:password_confirmation])
      check_registration
    end

  end

  def cancel_registration
    user = User.current_user
    if user && !user.person
      logout_user
      user.destroy
    end
    redirect_to main_app.root_path
  end

  def set_openid
    @user = User.find(params[:id])
    authenticate_with_open_id do |result, identity_url|
      if result.successful?
        @user.openid = identity_url
        if @user.save
          flash[:notice] = "OpenID successfully set"
          redirect_to(@user.person)
        else
          redirect_to(edit_user_path(@user))
        end
      else
        flash[:error] = result.message
        redirect_to(edit_user_path(@user))
      end
    end
  end

  def activate
    self.current_user = params[:activation_code].blank? ? false : User.find_by_activation_code(params[:activation_code])
    if logged_in? && !current_user.active?
      current_user.activate      
      if (current_user.person.projects.empty? && User.count>1)
        Mailer.welcome_no_projects(current_user, base_host).deliver
        logout_user
        flash[:notice] = "Signup complete! However, you will need to wait for an administrator to associate you with your project(s) before you can login."        
        redirect_to main_app.root_path
      else
        Mailer.welcome(current_user, base_host).deliver
        flash[:notice] = "Signup complete!"
        redirect_to current_user.person
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
          Mailer.forgot_password(user, base_host).deliver if Seek::Config.email_enabled
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
    person=Person.find(params[:user][:person_id]) unless (params[:user][:person_id]).nil?
    @user.person=person if !person.nil?

    #user was assigned to person, so auth update is needed
    do_auth_update = params[:user][:person_id]

    if params[:user]
      [:id, :person_id].each do |column_name|
        params[:user].delete(column_name)
      end
    end
    
    @user.attributes=params[:user]    

    respond_to do |format|
      
      if @user.save
        AuthLookupUpdateJob.add_items_to_queue(@user) if do_auth_update
        #user has associated himself with a person, so activation email can now be sent
        if !current_user.active?
          Mailer.signup(@user,base_host).deliver
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
      Mailer.signup(user,base_host).deliver
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

  def hide_guide_box
    if current_user
      current_user.show_guide_box = false
      current_user.save
    end
    render :update do |page|
      if current_user.nil?
        cookies[:hide_guide_box]={:value=>'true',:expires=>10.years.from_now}
      end
       page.visual_effect :fade, 'guide_box', :duration => 0.25
    end
  end
  protected
  
  def open_id_authentication(identity_url)
    # Pass optional :required and :optional keys to specify what sreg fields you want.
    # Be sure to yield registration, a third argument in the #authenticate_with_open_id block.
    authenticate_with_open_id(identity_url,        
        :required => [:email, :fullname,
                      'http://schema.openid.net/contact/email',
                      'http://openid.net/schema/contact/email',
                      'http://axschema.org/contact/email',
                      'http://schema.openid.net/namePerson',
                      'http://openid.net/schema/namePerson',
                      'http://axschema.org/namePerson']) do |result, identity_url, registration|
      case result.status
      when :missing
        failed_registration "Sorry, the OpenID server couldn't be found"
      when :invalid
        failed_registration "Sorry, but this does not appear to be a valid OpenID"
      when :canceled
        failed_registration "OpenID verification was canceled"
      when :failed
        failed_registration "Sorry, the OpenID verification failed"
      when :successful
        if !User.find_by_openid(identity_url)
          @openid_details = {}
          @openid_details[:email] = registration['email']
          name = registration['fullname']
          ax_response = OpenID::AX::FetchResponse.from_success_response(request.env[Rack::OpenID::RESPONSE])
          @openid_details[:email] ||= ax_response['http://schema.openid.net/contact/email'].first
          @openid_details[:email] ||= ax_response['http://openid.net/schema/contact/email'].first
          @openid_details[:email] ||= ax_response['http://axschema.org/contact/email'].first
          name ||= ax_response['http://schema.openid.net/namePerson'].first
          name ||= ax_response['http://openid.net/schema/namePerson'].first
          name ||= ax_response['http://axschema.org/namePerson'].first
          if name
            @openid_details[:first_name], @openid_details[:last_name] = name.split(" ", 2)
          end
          @user = User.new(:openid => identity_url)
          check_registration
        else
          failed_registration "There is already a user registered with the given OpenID URL"
        end
      end
    end
  end
  
  private 
  
  def check_registration       
    if @user.save
      successful_registration
    else
      failed_registration @user.errors.full_messages.to_sentence
    end
  end
  
  def failed_registration(message)
    flash[:error] = message
    redirect_to(new_user_url)
  end
  
  def successful_registration
    @user.activate unless activation_required?
    self.current_user = @user
    @openid_details ||= nil
    redirect_to(select_people_path(:openid_details => @openid_details))
  end
  
  def activation_required?
    Seek::Config.activation_required_enabled && User.count>1
  end

end
