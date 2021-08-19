class ContactRequestMessageLog < MessageLog

  default_scope { where(message_type: CONTACT_REQUEST) }

  # message logs created since the recent period, for that person and interested item
  def self.recent_contact_requests(person, item)
    ContactRequestMessageLog.where(subject: item).where(sender: person).recent
  end

  # records a contact request for a sender and item, along with any details provided
  def self.log_contact_request(sender, item, details)
    ContactRequestMessageLog.create(subject: item, sender: sender, details: details)
  end
end