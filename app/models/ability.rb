class Ability

  def initialize(user)
    @person = (user.is_a?(User) ? user.try(:person) : user)
  end

  def can?(action, item)
    Seek::Permissions::Authorization.authorized_by_role?(action.to_s, item, @person.try(:user))
  end

  def cannot?(action, item)
    !can?(action, item)
  end

end
