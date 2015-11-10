require 'test_helper'

class BiosamplesHelperTest < ActionView::TestCase
  def test_asset_links_for_sop
    admin = Factory(:admin)
    User.with_current_user admin.user do
      sop1 = Factory(:sop, :contributor=>admin.user,:title=>"test_sop1")
      sop2 = Factory(:sop, :title=>"test_sop2")
      assert sop1.can_view?
      assert !sop2.can_view?

      sop_links = asset_links [sop1,sop2]
      assert_equal 1, sop_links.count
      link1 = link_to('test_sop1', "/sops/#{sop1.id}")
      link2 = link_to('test_sop2', "/sops/#{sop2.id}")
      assert sop_links.include?link1
      assert !sop_links.include?(link2)
    end
  end
end
