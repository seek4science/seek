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
      #if the person has registered but has not yet selected a profile then go to the select person page
      #otherwise login normally
      if current_user.person.nil?
          redirect_to(select_people_path)
      else
        respond_to do |format|
          flash[:notice] = "Logged in successfully"
          
          if !params[:called_from].blank? && params[:called_from][:controller] != "sessions"
            unless params[:called_from][:id].blank?
              return_to_url = url_for(:controller => params[:called_from][:controller], :action => params[:called_from][:action], :id => params[:called_from][:id])
            else
              return_to_url = url_for(:controller => params[:called_from][:controller], :action => params[:called_from][:action])
            end
          else
            unless session[:return_to] and !session[:return_to].empty?
              return_to_url = request.env['HTTP_REFERER']
            else
              return_to_url = session[:return_to]
            end
          end
          
          format.html { return_to_url.nil? || (return_to_url && URI.parse(return_to_url).path == '/') ? redirect_to(root_url) : redirect_to(return_to_url) }
        end
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
