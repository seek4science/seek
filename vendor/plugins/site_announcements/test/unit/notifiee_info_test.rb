class NotifieeInfoTest < ActiveSupport::TestCase
  
  def setup
    load_schema
    Fixtures.create_fixtures(File.join(File.dirname(__FILE__), '../fixtures'),"site_announcements")
  end
  
  def test_unique_key_generation
    
    #the SiteAnnouncementCategory is used as a dummy notifiee
    c=SiteAnnouncementCategory.new
    c.save!
    
    n=NotifieeInfo.new(:notifiee=>c)    
    assert_nil n.unique_key
    n.save!
    assert_not_nil n.unique_key
  end
end