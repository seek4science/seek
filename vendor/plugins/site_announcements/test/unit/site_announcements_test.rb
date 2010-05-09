require 'test_helper'

class SiteAnnouncementsTest < ActiveSupport::TestCase

  

  def setup
    load_schema
    Fixtures.create_fixtures(File.join(File.dirname(__FILE__), '../fixtures'),"site_announcements")
  end
  
  test "using fixtures" do
    assert_not_nil SiteAnnouncement.find(:first)
  end
end
