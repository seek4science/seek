class UsersController < ApplicationController
  
  layout 'logged_out'
  
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
      @user.activate
      self.current_user = @user
      redirect_to(url_for(:controller=>"people", :action=>"edit", :id=>@user.person))
      flash[:notice] = "Thanks for signing up!"
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

end
