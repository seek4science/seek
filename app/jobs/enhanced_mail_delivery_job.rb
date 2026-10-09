# frozen_string_literal: true

class EnhancedMailDeliveryJob < ActionMailer::MailDeliveryJob
  before_perform do
    Seek::Config.settings_cache # Perform config propagation if needed
  end

  around_perform do |_job, block|
    if Seek::Config.email_enabled
      block.call
    end
  end
end
