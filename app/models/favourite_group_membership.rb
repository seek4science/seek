class FavouriteGroupMembership < ActiveRecord::Base
  belongs_to :favourite_group
  belongs_to :person
  
  validates_presence_of :favourite_group_id, :person_id, :access_type

  after_save :queue_update_auth_table
  after_destroy :queue_update_auth_table

  def queue_update_auth_table
    people = [Person.find_by_id(person_id)]

    people << Person.find_by_id(person_id_was) unless person_id_was.blank?

    AuthLookupUpdateJob.add_items_to_queue people.compact
  end


end
