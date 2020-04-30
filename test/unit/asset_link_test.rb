require 'test_helper'

class AssetLinkTest < ActiveSupport::TestCase

  test 'validation' do
    asset = Factory(:sop)
    link = AssetLink.new(url:'http://fish.com', asset:asset)
    assert link.valid?

    link.url = nil
    refute link.valid?

    link.url = ''
    refute link.valid?

    link.url = 'fish'
    refute link.valid?

    link.url = 'fish.com'
    refute link.valid?

    link.url = 'https://fish.com'
    assert link.valid?

    link.asset = nil
    refute link.valid?
  end

  test 'link_type' do
    # if this changes, then the database entries need updating
    assert_equal 'discussion', AssetLink::DISCUSSION

    link1 = Factory(:asset_link)
    link2 = Factory(:asset_link, url:'http://google.com',link_type:'another')

    assert_equal [link1], AssetLink.discussion
  end


end