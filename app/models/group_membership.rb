class GroupMembership < ActiveRecord::Base
  belongs_to :person
  belongs_to :work_group
  has_one :project, :through=>:work_group

  has_and_belongs_to_many :project_roles

  after_save :queue_update_auth_table
  after_destroy :queue_update_auth_table

  def queue_update_auth_table
    people = [Person.find_by_id(person_id)]
    people << Person.find_by_id(person_id_was) unless person_id_was.blank?

    AuthLookupUpdateJob.add_items_to_queue people.compact
  end
end
