FactoryBot.define do
  # Permission
  factory(:permission, class: Permission) do
    association :contributor, factory: :person, strategy: :create
    association :policy
    access_type { Policy::NO_ACCESS }
  end
  
  factory(:edit_permission, class: Permission) do
    association :contributor, factory: :person, strategy: :create
    association :policy
    access_type { Policy::EDITING }
  end
  
  factory(:manage_permission, class: Permission) do
    association :contributor, factory: :person, strategy: :create
    association :policy
    access_type { Policy::MANAGING }
  end
  
  # Policy
  factory(:policy, class: Policy) do
    name { 'test policy' }
    access_type { Policy::NO_ACCESS }
  end
  
  factory(:private_policy, parent: :policy) do
    access_type { Policy::NO_ACCESS }
  end
  
  factory(:public_policy, parent: :policy) do
    access_type { Policy::MANAGING }
  end
  
  factory(:all_sysmo_viewable_policy, parent: :policy) do
    access_type { Policy::VISIBLE }
    sharing_scope { Policy::ALL_USERS }
  end
  
  factory(:all_sysmo_downloadable_policy, parent: :policy) do
    access_type { Policy::ACCESSIBLE }
    sharing_scope { Policy::ALL_USERS }
  end
  
  factory(:publicly_viewable_policy, parent: :policy) do
    access_type { Policy::VISIBLE }
  end
  
  factory(:public_download_and_no_custom_sharing, parent: :policy) do
    access_type { Policy::ACCESSIBLE }
  end
  
  factory(:editing_public_policy, parent: :policy) do
    access_type { Policy::EDITING }
  end
  
  factory(:downloadable_public_policy, parent: :policy) do
    access_type { Policy::ACCESSIBLE }
  end
  
  # FavouriteGroup
  factory(:favourite_group) do
    association :user
    name { 'A Favourite Group' }
  end
  
  # FavouriteGroupMembership
  factory(:favourite_group_membership) do
    association :person
    association :favourite_group
    access_type { Policy::VISIBLE }
  end
  
  # SpecialAuthCode
  factory(:special_auth_code) do
    association :asset, factory: :data_file
  end
end
