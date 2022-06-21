# Message logs related to requests to contact the owner of an item
class ContactRequestMessageLog < MessageLog
  default_scope { where(message_type: :contact_request) }
  scope :pending_requests, ->(projects) { where(subject: projects).pending }

  # message logs created since the recent period, for that person and interested item
  scope :recent_requests, lambda { |person, item|
    where(subject: item).where(sender: person).recent
  }

  # records a contact request for a sender and item, along with any details provided
  def self.log_request(sender:, item:, details:)
    ContactRequestMessageLog.create(subject: item, sender: sender, details: details)
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
