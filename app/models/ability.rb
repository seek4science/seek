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
      person.roles.each do |role|
        send(role, person)
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

  def project_manager project_manager

  end

  #asset manager can manage the assets belonging to their project
  def asset_manager asset_manager
     can [:manage_asset, :delete, :edit, :download, :view], :all do |item|
        asset_manager.is_asset_manager_of?(item)
     end
  end

  #gatekeeper can publish the assets belonging to their project if as well can manage or the item is waiting for his approval
  def gatekeeper gatekeeper
    can :publish, :all do |item|
      if gatekeeper.is_gatekeeper_of?(item) && !item.is_published?
       item.can_manage?(gatekeeper.user) || item.is_waiting_approval?(nil,1.year.ago)
      else
        false
      end
    end
  end
end