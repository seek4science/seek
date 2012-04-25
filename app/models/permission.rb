class Permission < ActiveRecord::Base
  belongs_to :contributor, :polymorphic => true
  belongs_to :policy
  
  validates_presence_of :contributor
  validates_presence_of :policy
  validates_presence_of :access_type

  after_save :queue_update_auth_table

  def queue_update_auth_table
    assets = policy.assets
    assets = assets | Policy.find_by_id(policy_id_was).try(:assets) unless policy_id_was.blank?
    AuthLookupUpdateJob.add_items_to_queue assets.compact
  end
  
  # TODO implement duplicate check in :before_create

  def controls_access_for? person
    contributor == person || try_block {contributor.people.include? person}
  end

  #precedence of permission types. Highest precedence is listed first
  @@precedence = ['Person', 'FavouriteGroup', 'WorkGroup', 'Project', 'Institution'].reverse

  #takes a list of permissions, and gives you the effective permission
  def self.choose_for person, list
    return nil if list.empty?
    list.inject do |p, p2|
      permissions = [p, p2]
      unless p.contributor_type == p2.contributor_type
        #return highest precedence
        permissions.max_by{|p| @@precedence.index(p.contributor_type)}
      else
        #if those match, return the highest access type
        permissions.max_by{|p| p.access_type_for person}
      end
    end
  end


  def allows_action? action, person
    Authorization.access_type_allows_action? action, access_type_for(person)
  end

  def access_type_for person
    #FIXME: move the access type out of the favourite group, if possible
    if contributor_type == 'FavouriteGroup'
      person.favourite_group_memberships.find_by_favourite_group_id(contributor.id).access_type
    else
      self.access_type
    end
  end
end