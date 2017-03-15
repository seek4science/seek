

module SiteAnnouncementsHelper
  def site_annoucements_headline
    headline = SiteAnnouncement.headline_announcement
    return '' unless headline # return empty string if there is no announcement
    render partial: 'site_announcements/headline_announcement', object: headline
  end

  def site_announcements_feed(options)
    options[:limit] ||= 5
    announcements = SiteAnnouncement.feed_announcements limit: options[:limit]
    render partial: 'site_announcements/feed_announcements', object: announcements, locals: { truncate_length: options[:truncate_length], limit: options[:limit] }
  end

  def site_announcement_attributes(announcement)
    attr = []
    attr << 'show in feed' if announcement.show_in_feed?
    attr << 'headline' if announcement.is_headline?
    attr << 'mail' if announcement.email_notification?
    attr
  end
end
