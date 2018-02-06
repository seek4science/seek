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

    @controller.send(:current_user=, user)
    User.current_user = user
  end

  def logout
    @controller.send(:clear_current_user)
    User.current_user = nil
  end

  def authorize_as(user)
    @request.env['HTTP_AUTHORIZATION'] = user ? ActionController::HttpAuthentication::Basic.encode_credentials(users(user).login, 'test') : nil
  end
end
