class AdminDefinedRoleProgramme < ApplicationRecord
  belongs_to :programme
  belongs_to :person


  after_commit :queue_update_auth_table, :if=>:persisted?
  before_destroy :queue_update_auth_table

  validates :programme,:person, presence:true
  validates :role_mask,numericality: {greater_than:0,less_than_or_equal_to:32}

  private

  def queue_update_auth_table
    AuthLookupUpdateQueue.enqueue(person)
  end

end
