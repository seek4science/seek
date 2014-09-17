class Permission < ActiveRecord::Base
  belongs_to :contributor, :polymorphic => true
  belongs_to :policy

  validates_presence_of :contributor
  validates_presence_of :policy
  validates_presence_of :access_type

  after_commit :queue_update_auth_table

  def queue_update_auth_table
    unless (previous_changes.keys - ["updated_at"]).empty?
      assets = policy.assets
      assets = assets | Policy.find_by_id(policy_id_was).try(:assets) unless policy_id_was.blank?
      AuthLookupUpdateJob.add_items_to_queue assets.compact
    end
  end
  
  # TODO implement duplicate check in :before_create

  def controls_access_for? person
    if contributor.respond_to?(:people)
      contributor.people.include? person
    else
      contributor == person
    end
  end

  #precedence of permission types. Highest precedence is listed first
  @@precedence = ['Person', 'FavouriteGroup', 'WorkGroup', 'Project', 'Institution']

  #takes a list of permissions, and gives you a list from the highest precedence to the lowest
  def self.sort_for person, list
    return [] if list.empty?
    #sort would list things from low to high, so the sort block will return -1 when p has a higher permission than p2
    list.sort do |p, p2|
      unless p.contributor_type == p2.contributor_type
        #@@precedence has a smaller index for higher precedence types
        p.compare_by(p2) {|p| @@precedence.index(p.contributor_type)}
      else
        #highest access type should come first so we need to reverse it
        p.compare_by(p2) {|p| p.access_type_for(person)} * -1
      end
    end
  end

  def compare_by(other)
    yield(self) <=> yield(other)
  end


  def allows_action? action, person
    Seek::Permissions::Authorization.access_type_allows_action? action, access_type_for(person)
  end

  def access_type_for person
    #FIXME: move the access type out of the favourite group, if possible
    if !person.nil? && contributor_type == 'FavouriteGroup'
      group = person.favourite_group_memberships.find_by_favourite_group_id(contributor.id)
      group.nil? ? self.access_type : group.access_type
    else
      self.access_type
    end
  end
end