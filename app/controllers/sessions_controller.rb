# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
 
  layout 'logged_out'
  
  # render new.rhtml
  def new
  end

  def create
    self.current_user = User.authenticate(params[:login], params[:password])
    if logged_in?
      if params[:remember_me] == "1"
        current_user.remember_me unless current_user.remember_token?
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      #if the person has registerd but has not yet selected a profile then go to the select person page
      #otherwise login normally
      if current_user.person.nil?
          redirect_to(select_people_path)
      else
        redirect_back_or_default('/')
        flash[:notice] = "Logged in successfully"
      end
            
    else
      flash[:error] = "Invalid login"
      redirect_to :action => 'new'
    end
  end

  def destroy
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_back_or_default('/')
  end
end
