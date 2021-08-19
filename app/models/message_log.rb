# records and tracks messages that have been sent, and when

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

  scope :recent, -> { where('created_at >= ?', RECENT_PERIOD.ago) }
  scope :pending, -> { where(response: nil) }

  def respond(comments)
    update_column(:response, comments)
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

  def sent_by_self?
    sender == User.current_user&.person
  end


end
