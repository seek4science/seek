class Ability
  include CanCan::Ability

  def initialize(user)

    alias_action  :show, :index, :search, :favourite, :favourite_delete,
                  :comment, :comment_delete, :comments, :comments_timeline, :rate,
                  :tag, :items, :statistics, :tag_suggestions, :preview, :to => :view
    alias_action  :named_download, :launch, :submit_job, :data, :execute, :plot, :explore, :to => :download
    alias_action  :new, :create, :update, :new_version, :create_version, :destroy_version, :edit_version, :update_version,
                  :new_item, :create_item, :edit_item, :update_item, :quick_add, :resolve_link, :to => :edit
    alias_action  :destroy, :destroy_item, :to => :delete
    alias_action  :preview_publish, :to => :publish

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
    can [:manage_asset, :delete, :edit, :download, :view], :all do |item|
      user = item.contributor
      asset_housekeeper.is_asset_housekeeper_of?(item) &&
          (item.managers.empty? || (item.projects - user.person.former_projects).none?)
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