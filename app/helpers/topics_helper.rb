module TopicsHelper
  def avatar_for(user)
    avatar(user.person, 30)
  end
end
