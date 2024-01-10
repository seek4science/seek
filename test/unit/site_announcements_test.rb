require 'test_helper'

class SiteAnnouncementsTest < ActiveSupport::TestCase

  test 'using fixtures' do
    assert_not_nil SiteAnnouncement.first
  end

  test 'headline' do
    hl = SiteAnnouncement.headline_announcement
    assert_not_nil hl
    assert_equal 'This is a headline and feed announcement', hl.title

    hl.expires_at = Time.now - 1.hour
    hl.save!

    hl = SiteAnnouncement.headline_announcement
    assert_not_nil hl
    assert_equal 'This is a headline only announcement', hl.title

    hl.expires_at = Time.now - 1.hour
    hl.save!

    assert_nil SiteAnnouncement.headline_announcement
  end

  test 'new headline comes out top' do
    hl = SiteAnnouncement.headline_announcement
    assert_not_nil hl
    assert_equal 'This is a headline and feed announcement', hl.title

    ann = SiteAnnouncement.new(title: 'brand new', expires_at: Time.now + 1.day, is_headline: true)
    ann.save!

    hl = SiteAnnouncement.headline_announcement
    assert_not_nil hl
    assert_equal 'brand new', hl.title
  end

  test 'feed' do
    list = SiteAnnouncement.feed_announcements
    assert_equal 2, list.size
    assert_equal 'This is a headline and feed announcement', list[0].title
    assert_equal 'This is a basic announcement', list[1].title

    list = SiteAnnouncement.feed_announcements limit: 1
    assert_equal 1, list.size
    assert_equal 'This is a headline and feed announcement', list[0].title
  end
end
