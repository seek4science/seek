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

  #access manager can manage the assets belonging to their project, except the entire private assets
  def asset_manager asset_manager
     can [:manage_asset, :delete, :edit, :download, :view], :all do |item|
        if ((item.respond_to?(:projects) && asset_manager.try(:projects)) and !(item.projects & asset_manager.projects).empty?) && item.respond_to?(:policy)
            policy = item.policy
            if policy.access_type > Policy::NO_ACCESS
              true
            else
              creators = item.is_downloadable? ? item.creators : []
              contributor = item.contributor.kind_of?(Person) ? item.contributor : item.contributor.try(:person)
              grouped_people_by_access_type = policy.summarize_permissions creators, [], contributor
              !policy.is_entirely_private? grouped_people_by_access_type, contributor
            end
        else
          false
        end
     end
  end

  def gatekeeper gatekeeper
    can :publish, :all do |item|
      if item.respond_to?(:projects) && gatekeeper.try(:projects) && item.respond_to?(:policy)
       !(item.projects & gatekeeper.projects).empty? && item.can_manage?(gatekeeper.try(:user))
      else
        false
      end
    end
  end
end