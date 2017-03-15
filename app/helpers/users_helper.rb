module UsersHelper
  def current_user_id
    User.current_user.nil? ? 0 : User.current_user.id
  end
end
