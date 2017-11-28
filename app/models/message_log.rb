class MessageLog < ActiveRecord::Base
  # the different types of messages
  PROJECT_MEMBERSHIP_REQUEST = 1

  RECENT_PERIOD = 12.hours.freeze

  belongs_to :resource, polymorphic: true
  belongs_to :sender, class_name: 'Person'

  validates :resource, :message_type, :sender, presence: true
  validate :project_required_for_project_membership_request

  scope :project_membership_requests, -> { where('message_type = ?', PROJECT_MEMBERSHIP_REQUEST) }

  scope :recent, -> { where('created_at >= ?', RECENT_PERIOD.ago) }

  def self.recent_project_membership_requests(person, project)
    MessageLog.where("resource_type = 'Project' AND resource_id = ?", project.id).where(sender: person).project_membership_requests.recent
  end

  def self.log_project_membership_request(sender, project, details)
    MessageLog.create(resource: project, sender: sender, details: details, message_type: PROJECT_MEMBERSHIP_REQUEST)
  end

  private

  def project_required_for_project_membership_request
    if message_type == PROJECT_MEMBERSHIP_REQUEST
      unless resource.is_a?(Project)
        errors.add(:resource, 'must be a project for a project membership request')
      end
    end
  end
end
