class SiteAnnouncement < ActiveRecord::Base

  class BodyHelper
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper
  end

  belongs_to :site_announcement_category
  belongs_to :announcer,:polymorphic=>true

  named_scope :headline_announcements,:conditions=>(["is_headline = ? and expires_at > ? ",true,Time.now]),:order=>"created_at DESC",:limit=>1
  
  validates_presence_of :title

  def self.headline_announcement
    self.headline_announcements.first
  end

  def self.feed_announcements options={}
    options[:limit] ||= 5
    self.find(:all,:conditions=>(["show_in_feed = ?",true]),:order=>"created_at DESC",:limit=>options[:limit])
  end

  def body_html
    helper.auto_link(simple_format(h(body)))
  end


  private

  def helper
    @helper ||= BodyHelper.new
  end
  
end
