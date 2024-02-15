# superclass that handles records and tracks messages that have been sent, and when
# subclasses handle specific details and behaviour according to the message log type
# and this model shouldn't be used directly
class MessageLog < ApplicationRecord
  enum message_type: {
    project_membership_request: 1,
    contact_request: 2,
    programme_creation_request: 3, # no longer used
    project_creation_request: 4,
    activation_email: 5,
    project_importation_request: 6
  }

  belongs_to :subject, polymorphic: true
  belongs_to :sender, class_name: 'Person'

  validates :subject, :message_type, :sender, presence: true

  scope :pending, -> { where(response: nil) }
  scope :recent, -> { where('created_at >= ?', RECENT_PERIOD.ago) }

  # the period concidered recent, which can be used to prevent a repeat message until that period has passed
  RECENT_PERIOD = 12.hours.freeze

  def respond(comments)
    update_column(:response, comments)
  end

  def responded?
    response.present?
  end

  def sent_by_self?
    sender == User.current_user&.person
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
end
