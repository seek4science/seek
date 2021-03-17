# records and tracks messages that have been sent, and when

# FIXME: this is being used for more types than expected and is getting overloaded, worthy of being split into subclasses
# the different types of messages
class MessageLog < ApplicationRecord
  PROJECT_MEMBERSHIP_REQUEST = 1
  CONTACT_REQUEST = 2
  PROGRAMME_CREATION_REQUEST = 3
  PROJECT_CREATION_REQUEST = 4
  ACTIVATION_EMAIL = 5

  # the period concidered recent, which can be used to prevent a repeat message until that period has passed
  RECENT_PERIOD = 12.hours.freeze

  belongs_to :subject, polymorphic: true
  belongs_to :sender, class_name: 'Person'

  validates :subject, :message_type, :sender, presence: true
  validate :project_required_for_project_membership_request

  scope :recent, -> { where('created_at >= ?', RECENT_PERIOD.ago) }
  scope :pending, -> { where(response: nil) }

  scope :project_membership_requests, -> { where(message_type: PROJECT_MEMBERSHIP_REQUEST) }
  scope :contact_requests, -> { where(message_type: CONTACT_REQUEST) }
  scope :project_creation_requests, -> { where(message_type: PROJECT_CREATION_REQUEST) }
  scope :activation_email_logs, lambda { |person|
                                  where(message_type: ACTIVATION_EMAIL, subject: person).order(created_at: :asc)
                                }

  # project creation requests that haven't been responded to
  scope :pending_project_creation_requests, -> { project_creation_requests.pending }
  scope :pending_project_join_requests, ->(projects) { where(subject: projects).project_membership_requests.pending }

  # message logs created since the recent period, for that person and project
  scope :recent_project_membership_requests, lambda { |person, project|
                                               where(subject: project).where(sender: person).project_membership_requests.recent
                                             }

  def respond(comments)
    update_column(:response, comments)
  end

  def self.log_project_creation_request(sender, programme, project, institution)
    details = {}
    details[:institution] = institution.attributes
    details[:project] = project.attributes
    details[:programme] = programme&.attributes
    # FIXME: needs a subject, but can't use programme as it will save it if it is new
    MessageLog.create(subject: sender, sender: sender, details: details.to_json, message_type: PROJECT_CREATION_REQUEST)
  end

  # records a project membership request for a sender and project, along with any details provided
  def self.log_project_membership_request(sender, project, institution, comments)
    details = { comments: comments }
    details[:institution] = institution.attributes if institution
    MessageLog.create(subject: project, sender: sender, details: details.to_json,
                      message_type: PROJECT_MEMBERSHIP_REQUEST)
  end

  # message logs created since the recent period, for that person and interested item
  def self.recent_contact_requests(person, item)
    MessageLog.where(subject: item).where(sender: person).contact_requests.recent
  end

  # records a contact request for a sender and item, along with any details provided
  def self.log_contact_request(sender, item, details)
    MessageLog.create(subject: item, sender: sender, details: details, message_type: CONTACT_REQUEST)
  end

  # logs when an activation email has been sent, and by whom
  def self.log_activation_email(sender)
    MessageLog.create(subject: sender, sender: sender, message_type: ACTIVATION_EMAIL)
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

  # whether the person can respond to the creation request
  # TODO: this will be refactored into a more general method
  def can_respond_project_creation_request?(user_or_person)
    return false unless message_type == PROJECT_CREATION_REQUEST
    return false if user_or_person.nil?
    

    person = user_or_person.person

    log_details = JSON.parse(details)

    return person.is_admin? if log_details['programme'].blank?

    programme = Programme.new(log_details['programme'])

    if programme.id.nil?
      person.is_admin?
    else
      (person.is_admin? && programme.site_managed?) || person.is_programme_administrator?(programme)
    end
  end

  def responded?
    response.present?
  end

  def sent_by_self?
    sender == User.current_user&.person
  end

  private

  def project_required_for_project_membership_request
    if message_type == PROJECT_MEMBERSHIP_REQUEST && !subject.is_a?(Project)
      errors.add(:subject, 'must be a project for a project membership request')
    end
  end
end
