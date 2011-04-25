module AuthenticatedTestHelper
  # Sets the current user in the session from the user fixtures.
  def login_as(user)
    user = users(user) unless user.class == User
    @request.session[:user_id] = user.try(:id)
    User.current_user = user
  end

  def logout
    @request.session[:user_id] = nil
  end

  def authorize_as(user)
    @request.env["HTTP_AUTHORIZATION"] = user ? ActionController::HttpAuthentication::Basic.encode_credentials(users(user).login, 'test') : nil
  end
end
