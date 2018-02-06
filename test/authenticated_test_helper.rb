module AuthenticatedTestHelper
  # Sets the current user in the session from the user fixtures.

  def login_as(user)
    user = users(user) unless user.class == User || user.class == Person
    user = user.user if user.class == Person
    @request.session[:user_id] = user.try(:id)
    @controller.send(:current_user=, user)
    User.current_user = user
  end

  def logout
    @controller.send(:current_user=, nil)
    @request.session[:user_id] = nil
    User.current_user = nil
  end

  def authorize_as(user)
    @request.env['HTTP_AUTHORIZATION'] = user ? ActionController::HttpAuthentication::Basic.encode_credentials(users(user).login, 'test') : nil
  end
end
