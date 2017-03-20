require 'test_helper'

class SiteAnnouncementTest < ActiveSupport::TestCase
  def test_body_html_generation
    a = SiteAnnouncement.new title: 'test announcement', body: 'This is a link to http://www.google.com, and this is an email to bob@email.com'
    html = a.body_html
    assert html.html_safe?
    assert html.include?("href=\"http://www.google.com\"")
    assert html.include?('mailto:bob@email.com')
  end
end
