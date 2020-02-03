class FavouriteGroupMembership < ApplicationRecord
  belongs_to :favourite_group
  belongs_to :person
  
  validates_presence_of :favourite_group_id, :person_id, :access_type

  after_commit :queue_update_auth_table

  def queue_update_auth_table
    people = [Person.find_by_id(person_id)]

    people << Person.find_by_id(person_id_before_last_save) unless person_id_before_last_save.blank?

    AuthLookupUpdateQueue.enqueue(people.compact)
  end

  def allows_action?(action)
    Seek::Permissions::Authorization.access_type_allows_action?(action, self.access_type)
  end

  def affected_people
    [person]
  end

end
