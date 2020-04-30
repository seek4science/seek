require 'test_helper'

class AssetLinkTest < ActiveSupport::TestCase

  test 'validation' do
    asset = Factory(:sop)
    link = AssetsLink.new(url:'http://fish.com',asset:asset)
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

end