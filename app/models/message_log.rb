# records and tracks messages that have been sent, and when
class MessageLog < ApplicationRecord
  # the different types of messages
  PROJECT_MEMBERSHIP_REQUEST = 1
  CONTACT_REQUEST = 2
  PROGRAMME_CREATION_REQUEST = 3
  PROJECT_CREATION_REQUEST = 4

  # the period concidered recent, which can be used to prevent a repeat message until that period has passed
  RECENT_PERIOD = 12.hours.freeze

  belongs_to :resource, polymorphic: true
  belongs_to :sender, class_name: 'Person'

  validates :resource, :message_type, :sender, presence: true
  validate :project_required_for_project_membership_request

  scope :project_membership_requests, -> { where('message_type = ?', PROJECT_MEMBERSHIP_REQUEST) }
  scope :contact_requests, -> { where('message_type = ?', CONTACT_REQUEST) }

  scope :recent, -> { where('created_at >= ?', RECENT_PERIOD.ago) }

  # message logs created since the recent period, for that person and project
  def self.recent_project_membership_requests(person, project)
    MessageLog.where("resource_type = 'Project' AND resource_id = ?", project.id).where(sender: person).project_membership_requests.recent
  end

  def self.log_project_creation_request(sender, programme, project, institution)
    details = {}
    details[:institution] = institution.attributes
    details[:project] = project.attributes
    details[:programme] = programme.attributes
    # FIXME: needs a resource, but can't use programme as it will save it if it is new
    MessageLog.create(resource: sender, sender: sender, details: details.to_json, message_type: PROJECT_CREATION_REQUEST)
  end

  # records a project membership request for a sender and project, along with any details provided
  def self.log_project_membership_request(sender, project, institution, comments)
    details = {comments: comments}
    details[:institution]=institution.attributes if institution
    MessageLog.create(resource: project, sender: sender, details: details.to_json, message_type: PROJECT_MEMBERSHIP_REQUEST)

  end

  # message logs created since the recent period, for that person and interested item
  def self.recent_contact_requests(person, item)
    MessageLog.where("resource_type = ? AND resource_id = ?", item.class.name, item.id).where(sender: person).contact_requests.recent
  end

  # records a contact request for a sender and resource, along with any details provided
  def self.log_contact_request(sender, item, details)
     MessageLog.create(resource: item, sender: sender, details: details, message_type: CONTACT_REQUEST)
  end

  # how many hours remaining since the message was created, and the RECENT_PERIOD has elapsed
  def hours_until_next_allowed
    ((created_at - RECENT_PERIOD.ago) / 3600).to_i
  end

  # hours_until_next_allowed as a string, with hours pluralized correctly - e.g '2 hours', or '1 hour'
  def hours_until_next_allowed_str
    number_hours = hours_until_next_allowed
    "#{number_hours} #{'hour'.pluralize(number_hours)}"
  end

  def responded?
    response.present?
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
