module AuthenticatedTestHelper
  # Sets the current user in the session from the user fixtures.

  def login_as(user)
    user = case user
             when User
               user
             when Person
               user.user
             else
               users(user)
           end

    # Clear the current_user from the controller so authentication will happen again using the session
    @controller.send(:clear_current_user)
    @request.session[:user_id] = user.try(:id)
    User.current_user = user
  end

  def logout
    @controller.send(:clear_current_user)
    @request.session[:user_id] = nil
    User.current_user = nil
  end

  def authorize_as(user)
    @request.env['HTTP_AUTHORIZATION'] = user ? ActionController::HttpAuthentication::Basic.encode_credentials(users(user).login, 'test') : nil
  end
end
