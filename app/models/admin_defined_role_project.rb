class AdminDefinedRoleProject < ActiveRecord::Base
  belongs_to :project
  belongs_to :person


  validates :project,:person, presence:true
  validates :role_mask,numericality: {greater_than:0,less_than_or_equal_to:16}
  validate :project_belongs_to_person


  after_commit :queue_update_auth_table, :if=>:persisted?
  before_destroy :queue_update_auth_table

  private

  def queue_update_auth_table
    AuthLookupUpdateJob.add_items_to_queue person
  end

  def project_belongs_to_person
    unless (person.try(:projects) || []).include?(project)
      errors.add(:project,"the project must be one the person is a member of")
    end
  end
end
