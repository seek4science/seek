class AdminDefinedRoleProject < ApplicationRecord
  belongs_to :project
  belongs_to :person

  validates :project,:person, presence:true
  validates :role_mask,numericality: {greater_than:0,less_than_or_equal_to:16}


  after_commit :queue_update_auth_table, :if=>:persisted?
  before_destroy :queue_update_auth_table

  def roles
    Seek::Roles::Roles.instance.role_names_for_mask(role_mask)
  end

  private

  def queue_update_auth_table
    AuthLookupUpdateQueue.enqueue(person)
  end

end
