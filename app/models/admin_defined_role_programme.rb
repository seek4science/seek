class AdminDefinedRoleProgramme < ActiveRecord::Base
  belongs_to :programme
  belongs_to :person


  after_commit :queue_update_auth_table, :if=>:persisted?
  before_destroy :queue_update_auth_table
  after_destroy :remove_person_from_role

  validates :programme,:person, presence:true
  validates :role_mask,numericality: {greater_than:0,less_than_or_equal_to:32}

  private

  def queue_update_auth_table
    AuthLookupUpdateJob.new.add_items_to_queue person
  end

  def remove_person_from_role
    person.is_programme_administrator=false,programme
  end

end
