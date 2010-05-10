class SiteAnnouncement < ActiveRecord::Base
  belongs_to :site_announcement_category
  belongs_to :announcer,:polymorphic=>true
  
  validates_presence_of :title

  def self.headline_announcements
    self.find(:first,:conditions=>(["is_headline = true and expires_at > ? ",Time.now]),:order=>"created_at DESC")
  end

  def self.feed_announcements options={}
    options[:limit] ||= 5
    self.find(:all,:conditions=>(["show_in_feed = true"]),:order=>"created_at DESC",:limit=>options[:limit])

  end
end
