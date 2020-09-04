class SendAnnouncementEmailsJob < SeekEmailJob
  BATCHSIZE = 50

  attr_reader :site_announcement_id, :offset

  def initialize(site_annoucement_id, offset = 0)
    @site_announcement_id = site_annoucement_id
    @offset = offset
  end

  def perform
    super if Seek::Config.email_enabled
  end

  def perform_job(announcement)
    NotifieeInfo.where(receive_notifications: true).offset(@offset).limit(BATCHSIZE).each do |notifiee_info|
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

    @offset += BATCHSIZE
  end

  def follow_on_job?
    @offset < NotifieeInfo.count
  end

  def gather_items
    [SiteAnnouncement.find_by_id(site_announcement_id)].compact
  end

  def default_priority
    3
  end
end
