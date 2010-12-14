class FavouriteGroup < ActiveRecord::Base
  validates_presence_of :name
  
  # allow same group names, but only if these belong to different users
  validates_uniqueness_of :name, :scope => :user_id
  
  belongs_to :user
  has_many :favourite_group_memberships, :dependent => :destroy
  has_many :people, :through => :favourite_group_memberships
  
  has_many :permissions, :as => :contributor, :dependent => :destroy
  
  
  # constants containing names of white/black list groups;
  # these groups are to be stored per user within favourite_groups table -
  # and the names should be chosen in such a way that the users would not
  # want to pick such names themself 
  BLACKLIST_NAME = "__blacklist__"
  WHITELIST_NAME = "__whitelist__"
  
  # defaults for access types in BLACKLIST and WHITELIST groups
  BLACKLIST_ACCESS_TYPE = Policy::NO_ACCESS
  WHITELIST_ACCESS_TYPE = Policy::ACCESSIBLE
  
  
  # check if current favourite group is a blacklist or whitelist
  def is_whitelist_or_blacklist?
    return [FavouriteGroup::BLACKLIST_NAME, FavouriteGroup::WHITELIST_NAME].include?(self.name)
  end
  
  # return all favourite group [name, id] pairs for a particular user
  def self.get_all_without_blacklists_and_whitelists(user_id)
    all_groups = FavouriteGroup.find(:all, :conditions => {:user_id => user_id})
    return all_groups.collect { |g| [g.name, g.id] unless [FavouriteGroup::WHITELIST_NAME, FavouriteGroup::BLACKLIST_NAME].include?(g.name) }.compact
  end
end
