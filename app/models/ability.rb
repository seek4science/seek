class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # for guest
    person = user.person
    person.roles.each { |role| send(role) } if person
  end

  def admin
    can :manage, :all
  end
end