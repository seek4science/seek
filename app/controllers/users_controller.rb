class UsersController < ApplicationController
  
    layout 'logged_out'
    
    before_filter :find_user_auth, :only=>[:edit, :update]
  
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
  
    def edit
        @user = User.find(params[:id])
    end
  
    def update
        @user = User.find(params[:id])
      
        @user.attributes=params[:user]
      
        respond_to do |format| 
            if @user.save
                format.html { redirect_to person_path(@user.person) }
            else 
                format.html { render :action => 'edit' }
            end 
        end  
    end
    
    def find_user_auth
    begin
      @user = User.find(params[:id], :conditions => ["id = ?", current_user.id])
    rescue ActiveRecord::RecordNotFound
      error("User not found (id not authorized)", "is invalid (not owner)")
      return false
    end
    
    unless @user
      error("User not found (or not authorized)", "is invalid (not owner)")
      return false
    end
    
    
  end
  
  private

  def error(notice, message)
    flash[:error] = notice
    (err = User.new.errors).add(:id, message)
    
    respond_to do |format|
      format.html { redirect_to root_url }
    end
  end

end
