class SiteAnnouncement < ActiveRecord::Base

  class BodyHelper
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper
  end

  belongs_to :site_announcement_category
  belongs_to :announcer,:polymorphic=>true

  scope :headline_announcements,
        -> { where('is_headline = ? and expires_at > ? ', true, Time.now).order('created_at DESC').limit(1) }
  
  validates_presence_of :title

  after_create :send_announcement_emails

  def send_announcement_emails
    if email_notification?
      SendAnnouncementEmailsJob.new(id).queue_job
    end
  end

  def self.headline_announcement
    self.headline_announcements.first
  end

  def self.feed_announcements options={}
    options[:limit] ||= 5
    self.where(["show_in_feed = ?",true]).order("created_at DESC").limit(options[:limit])
  end

  def body_html
    helper.simple_format(helper.auto_link(body), {}, sanitize: false).html_safe
  end

  private

  def helper
    @helper ||= BodyHelper.new
  end
  
end
