module SessionsHelper

  #a person can be logged in but not fully registered during
  #the registration process whilst selecting or creating a profile
  def logged_in_and_registered?
    logged_in? && current_user.person
  end

  #returns true if there is somebody logged in and they are an admin
  def admin_logged_in?
    logged_in_and_registered? && current_user.person.is_admin?
  end
  
end