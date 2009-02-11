class FavouriteGroup < ActiveRecord::Base
  validates_presence_of :name
  
  # allow same group names, but only if these belong to different users
  validates_uniqueness_of :name, :scope => :user_id
  
  has_many :favourite_group_memberships, :dependent => :destroy
  has_many :permissions, :as => :contributor, :dependent => :destroy
  
  
  # constants containing names of white/black list groups;
  # these groups are to be stored per user within favourite_groups table -
  # and the names should be chosen in such a way that the users would not
  # want to pick such names themself 
  BLACKLIST_NAME = "__blacklist__"
  WHITELIST_NAME = "__whitelist__"
  
  
  # return all favourite group [name, id] pairs for a particular user
  def self.get_all_without_blacklists_and_whitelists(user_id)
    all_groups = FavouriteGroup.find(:all, :conditions => {:user_id => user_id})
    return all_groups.collect { |g| [g.name, g.id] unless [FavouriteGroup::WHITELIST_NAME, FavouriteGroup::BLACKLIST_NAME].include?(g.name) }.compact
  end
end
