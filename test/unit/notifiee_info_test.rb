require 'test_helper'

class NotifieeInfoTest < ActiveSupport::TestCase

  def test_unique_key_generation
    # the SiteAnnouncementCategory is used as a dummy notifiee
    c = SiteAnnouncementCategory.new
    c.save!

    n = NotifieeInfo.new(notifiee: c)
    assert_nil n.unique_key
    n.save!
    assert_not_nil n.unique_key
  end
end

#  def test_notifiee_info_is_deleted_when_notifiee_is
#    c=SiteAnnouncementCategory.new
#    c.save!
#
#    n=NotifieeInfo.new(:notifiee=>c)
#    n.save!
#
#    assert_difference("NotifieeInfo.count",-1) do
#      assert_difference("SiteAnnouncementCategory.count",-1) do
#        c.destroy
#      end
#    end
#
#    assert_nil NotifieeInfo.find_by_id(n.id)
#  end

#  def test_notifiee_isnt_deleted_when_notifiee_info_is
#    c=SiteAnnouncementCategory.new
#    c.save!
#
#    n=NotifieeInfo.new(:notifiee=>c)
#    n.save!
#
#    assert_no_difference("SiteAnnouncementCategory.count") do
#      n.destroy
#    end
#
#    assert_not_nil SiteAnnouncementCategory.find_by_id(c.id)
#  end
# end
