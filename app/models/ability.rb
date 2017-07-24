class Ability
  include CanCan::Ability

  def initialize(user)
    person = user.try(:person)
    if person
      person.projects.each do |proj|
        person.roles_for_project(proj).each do |role|
          send(role, person)
        end
      end

    end
  end

  def default_alias_actions
    {}
  end


  def admin admin

  end

  def pal pal

  end

  def project_administrator project_administrator

  end

  #asset housekeeper can manage the assets belonging to their project
  def asset_housekeeper asset_housekeeper
    can [:manage, :delete, :edit, :download, :view], :all do |item|
      # Check if ALL the managers of the items are no longer involved with ANY of the item's projects
      asset_housekeeper.is_asset_housekeeper_of?(item) && item.asset_housekeeper_can_manage?
    end
  end

  #asset gatekeeper can publish the assets belonging to their project if as well can manage or the item is waiting for his approval
  def asset_gatekeeper asset_gatekeeper
    can :publish, :all do |item|
      if asset_gatekeeper.is_asset_gatekeeper_of?(item)
        if item.can_manage?(asset_gatekeeper.user) && !item.is_published?
          true
        elsif !item.is_published? && item.is_waiting_approval?(nil, 5.years.ago)
          true
        else
          false
        end
      else
        false
      end
    end
  end
end