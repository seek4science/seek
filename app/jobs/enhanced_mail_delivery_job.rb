# frozen_string_literal: true

class EnhancedMailDeliveryJob < ActionMailer::MailDeliveryJob
  # makes sure any changes to the smtp and host settings are picked up without having to restart delayed job
  before_perform do
    # make sure the SMTP,site_base_host configuration is in sync with current SEEK settings
    Seek::Config.smtp_propagate
    Seek::Config.site_base_host_propagate
  end
end
