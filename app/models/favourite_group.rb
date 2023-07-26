class FavouriteGroup < ApplicationRecord
  validates_presence_of :name
  
  # allow same group names, but only if these belong to different users
  validates_uniqueness_of :name, :scope => :user_id
  
  belongs_to :user
  has_many :favourite_group_memberships, :dependent => :destroy
  has_many :people, :through => :favourite_group_memberships
  
  has_many :permissions, :as => :contributor, :dependent => :destroy

  #TODO: update to title in the table
  alias_attribute :title,:name
  
  # constants containing names of white/black list groups;
  # these groups are to be stored per user within favourite_groups table -
  # and the names should be chosen in such a way that the users would not
  # want to pick such names themself 
  DENYLIST_NAME = "__denylist__"
  ALLOWLIST_NAME = "__allowlist__"
  
  # defaults for access types in DENYLIST and ALLOWLIST groups
  DENYLIST_ACCESS_TYPE = Policy::NO_ACCESS
  ALLOWLIST_ACCESS_TYPE = Policy::ACCESSIBLE

  # check if current favourite group is a denylist or allowlist
  def is_allowlist_or_denylist?
    return [FavouriteGroup::DENYLIST_NAME, FavouriteGroup::ALLOWLIST_NAME].include?(self.name)
  end
  
  # return all favourite group [name, id] pairs for a particular user
  def self.get_all_without_denylists_and_allowlists(user_id)
    all_groups = FavouriteGroup.where(:user_id => user_id)
    return all_groups.collect { |g| [g.name, g.id] unless [FavouriteGroup::ALLOWLIST_NAME, FavouriteGroup::DENYLIST_NAME].include?(g.name) }.compact
  end
end
