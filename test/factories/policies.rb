# Permission
Factory.define(:permission, class: Permission) do |f|
  f.association :contributor, factory: :person
  f.association :policy
  f.access_type Policy::NO_ACCESS
end

# Policy
Factory.define(:policy, class: Policy) do |f|
  f.name 'test policy'
  f.access_type Policy::NO_ACCESS
end

Factory.define(:private_policy, parent: :policy) do |f|
  f.access_type Policy::NO_ACCESS
end

Factory.define(:public_policy, parent: :policy) do |f|
  f.access_type Policy::MANAGING
end

Factory.define(:all_sysmo_viewable_policy, parent: :policy) do |f|
  f.access_type Policy::VISIBLE
  f.sharing_scope Policy::ALL_USERS
end

Factory.define(:all_sysmo_downloadable_policy, parent: :policy) do |f|
  f.access_type Policy::ACCESSIBLE
  f.sharing_scope Policy::ALL_USERS
end

Factory.define(:publicly_viewable_policy, parent: :policy) do |f|
  f.access_type Policy::VISIBLE
end

Factory.define(:public_download_and_no_custom_sharing, parent: :policy) do |f|
  f.access_type Policy::ACCESSIBLE
end

Factory.define(:editing_public_policy, parent: :policy) do |f|
  f.access_type Policy::EDITING
end

Factory.define(:downloadable_public_policy, parent: :policy) do |f|
  f.access_type Policy::ACCESSIBLE
end

# FavouriteGroup
Factory.define(:favourite_group) do |f|
  f.association :user
  f.name 'A Favourite Group'
end

# FavouriteGroupMembership
Factory.define(:favourite_group_membership) do |f|
  f.association :person
  f.association :favourite_group
  f.access_type 1
end

# SpecialAuthCode
Factory.define(:special_auth_code) do |f|
  f.association :asset, factory: :data_file
end
