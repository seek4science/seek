FactoryBot.define do
  # SiteAnnouncement
  factory :site_announcement do
    sequence(:title) { |n| "Announcement #{n}" }
    sequence(:body) { |n| "This is the body for announcement #{n}" }
    association :announcer, factory: :admin
    expires_at { 5.days.since }
    email_notification { false }
    is_headline { false }
  end
  
  factory :headline_announcement, parent: :site_announcement do
    is_headline { true }
    title { 'a headline announcement' }
  end
  
  factory :feed_announcement, parent: :site_announcement do
    show_in_feed { true }
    title { 'a feed announcement' }
  end
  
  factory :mail_announcement, parent: :site_announcement do
    email_notification { true }
    title { 'a mail announcement' }
    body { 'this is a mail announcement' }
  end
end
