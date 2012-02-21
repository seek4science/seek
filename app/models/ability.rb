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

  #access manager can manage the assets belonging to their project, except the entire private assets
  def asset_manager asset_manager
     can :manage, :all do |item|
        if ((item.respond_to?(:projects) && asset_manager.try(:projects)) and !(item.projects & asset_manager.projects).empty?) && item.respond_to?(:policy)
            policy = item.policy
            if policy.access_type != Policy::NO_ACCESS
              true
            else
              grouped_people_by_access_type = policy.summarize_permissions item.creators, item.contributor.try(:person)
              grouped_people_by_access_type.delete Policy::DETERMINED_BY_GROUP
              grouped_people_by_access_type.delete Policy::NO_ACCESS
              people_with_permission = []
              grouped_people_by_access_type.each_value do |value|
                 people_with_permission |= value
              end
              !(people_with_permission.collect{|person| person[0]} - [item.contributor.try(:person).try(:id)]).empty?
            end
        else
          false
        end
     end
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