class GroupMembership < ActiveRecord::Base
  belongs_to :person
  belongs_to :work_group
  has_one :project, :through=>:work_group

  has_and_belongs_to_many :project_roles

  after_save :remember_previous_person
  after_commit :queue_update_auth_table

  validates :work_group,:presence => {:message=>"A workgroup is required"}

  def remember_previous_person
    @previous_person_id = person_id_was
  end

  def queue_update_auth_table
    people = [Person.find_by_id(person_id)]
    people << Person.find_by_id(@previous_person_id) unless @previous_person_id.blank?

    AuthLookupUpdateJob.add_items_to_queue people.compact
  end

end
