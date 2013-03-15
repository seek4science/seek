SiteAnnouncement.class_eval do
  after_create :send_announcement_emails

  def send_announcement_emails
    if email_notification?
      SendAnnouncementEmailsJob.create_job(id, 1)
    end
  end
end