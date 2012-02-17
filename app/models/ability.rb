class Ability
  include CanCan::Ability

  def initialize(user)
    person = user.try(:person)
    if person
      person.roles.each do |role|
        send(role, person)
      end
    end
  end

  def admin admin

  end

  def pal pal

  end

  def project_manager project_manager

  end

  def publisher publisher
    can :publish, :all do |item|
      if item.respond_to?(:projects) && publisher.try(:projects)
       !(item.projects & publisher.projects).empty?
      else
        false
      end
    end
  end
end