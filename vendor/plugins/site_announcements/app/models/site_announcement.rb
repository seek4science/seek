class SiteAnnouncement < ActiveRecord::Base
  belongs_to :site_announcement_category
  belongs_to :announcer,:polymorphic=>true
  
  validates_presence_of :title
  
end
