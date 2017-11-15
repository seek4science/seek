# SiteAnnouncement
Factory.define :site_announcement do |f|
  f.sequence(:title) { |n| "Announcement #{n}" }
  f.sequence(:body) { |n| "This is the body for announcement #{n}" }
  f.association :announcer, factory: :admin
  f.expires_at 5.days.since
  f.email_notification false
  f.is_headline false
end

Factory.define :headline_announcement, parent: :site_announcement do |f|
  f.is_headline true
  f.title 'a headline announcement'
end

Factory.define :feed_announcement, parent: :site_announcement do |f|
  f.show_in_feed true
  f.title 'a feed announcement'
end

Factory.define :mail_announcement, parent: :site_announcement do |f|
  f.email_notification true
  f.title 'a mail announcement'
  f.body 'this is a mail announcement'
end
