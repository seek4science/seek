SiteAnnouncement.class_eval do
  after_create :send_announcement_emails

  def send_announcement_emails
    if email_notification?
      SendAnnouncementEmailsJob.new(id).queue_job
    end
  end
end
