class SendAnnouncementEmailsJob < SeekEmailJob
  BATCHSIZE = 50

  attr_reader :site_announcement_id, :from_notifiee_id

  def initialize(site_annoucement_id, from_notifiee_id = 1)
    @site_announcement_id = site_annoucement_id
    @from_notifiee_id = from_notifiee_id
  end

  def perform_job(announcement)
    send_announcement_emails announcement, from_notifiee_id
    @from_notifiee_id = from_notifiee_id + BATCHSIZE + 1
  end

  def follow_on_job?
    NotifieeInfo.last && NotifieeInfo.last.id >= from_notifiee_id
  end

  def gather_items
    [SiteAnnouncement.find_by_id(site_announcement_id)].compact
  end

  def default_priority
    3
  end

  def allow_duplicate_jobs?
    false
  end

  def send_announcement_emails(site_announcement, from_notifiee_id)
    if Seek::Config.email_enabled
      NotifieeInfo.where(['id IN (?) AND receive_notifications=?', (from_notifiee_id..(from_notifiee_id + BATCHSIZE)), true]).each do |notifiee_info|
        begin
          unless notifiee_info.notifiee.nil?
            Mailer.announcement_notification(site_announcement, notifiee_info).deliver_now
          end
        rescue Exception => e
          if defined? Rails.logger
            Rails.logger.error "There was a problem sending an announcement email to #{notifiee_info.notifiee.try(:email)} - #{e.message}."
          end
        end
      end
    end
  end
end
