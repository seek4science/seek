module SessionsHelper

  #a person can be logged in but not fully registered during
  #the registration process whilst selecting or creating a profile
  def logged_in_and_registered?
    logged_in? && current_user.person
  end
  
end