require_dependency File.join(Gem.loaded_specs['site_announcements'].full_gem_path,'app','models','site_announcement')

SiteAnnouncement.class_eval do
  after_create :send_announcement_emails

  def send_announcement_emails
    if email_notification?
      SendAnnouncementEmailsJob.create_job(id, 1)
    end
  end
end