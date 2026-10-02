# frozen_string_literal: true

class EnhancedMailDeliveryJob < ActionMailer::MailDeliveryJob
  around_perform do |_job, block|
    if Seek::Config.email_enabled
      block.call
    end
  end
end
