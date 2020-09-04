class SendAnnouncementEmailsJob < EmailJob
  queue_with_priority 3
  BATCHSIZE = 50

  def perform(site_announcement_id, offset)
    announcement = SiteAnnouncement.find_by_id(site_announcement_id)
    return unless announcement && Seek::Config.email_enabled

    NotifieeInfo.where(receive_notifications: true).offset(offset).limit(BATCHSIZE).each do |notifiee_info|
      begin
        unless notifiee_info.notifiee.nil?
          Mailer.announcement_notification(announcement, notifiee_info).deliver_later
        end
      rescue Exception => e
        if defined? Rails.logger
          Rails.logger.error "There was a problem sending an announcement email to #{notifiee_info.notifiee.try(:email)} - #{e.message}."
        end
      end
    end

    offset += BATCHSIZE

    self.class.perform_later(site_announcement_id, offset) if offset < NotifieeInfo.count
  end
end
