# Message logs related to activation emails - to keep track of when the activation email
# was sent and how many times, to determine whether a reminder should be sent
class ActivationEmailMessageLog < MessageLog
  default_scope { where(message_type: :activation_email) }

  scope :activation_email_logs, lambda { |person|
    where(subject: person).order(created_at: :asc)
  }

  # logs when an activation email has been sent, and by whom
  def self.log_activation_email(sender)
    ActivationEmailMessageLog.create(subject: sender, sender: sender)
  end
end
