class SiteAnnouncement < ActiveRecord::Base
  belongs_to :site_announcement_category
  belongs_to :announcer,:polymorphic=>true

  named_scope :headline_announcements,:conditions=>(["is_headline = true and expires_at > ? ",Time.now]),:order=>"created_at DESC",:limit=>1
  
  validates_presence_of :title

  def self.headline_announcement
    self.headline_announcements.first
  end

  def self.feed_announcements options={}
    options[:limit] ||= 5
    self.find(:all,:conditions=>(["show_in_feed = true"]),:order=>"created_at DESC",:limit=>options[:limit])
  end

  def body_html
    auto_link(simple_format(h(body)))
  end
  
end
