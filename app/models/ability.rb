require 'cancan'

class Ability
  include CanCan::Ability

  def initialize(user)
    @user = user || User.new # for guest
    @user.person.roles.each { |role| send(role) }
  end

  def admin
    can :manage, :all
  end
end