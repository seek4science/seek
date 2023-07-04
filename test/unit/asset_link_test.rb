require 'test_helper'

class AssetLinkTest < ActiveSupport::TestCase

  test 'validation' do
    asset = FactoryBot.create(:sop)
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

    link.url = 'https://fish.com '
    assert link.valid? # it will have been stripped

    link.url = 'https://fish.com'
    assert link.valid?

    link.label='label'
    assert link.valid?

    link.label='a'*101
    refute link.valid?

    link.label=''
    assert link.valid?

    link.asset = nil
    refute link.valid?
  end

  test 'validates through asset' do
    asset = FactoryBot.build(:sop, discussion_links:[FactoryBot.build(:discussion_link, url:'not a url')])
    refute_empty asset.discussion_links
    refute asset.valid?
    assert_equal ['Discussion links url is not a valid URL'], asset.errors.full_messages

    asset.discussion_links.first.url='http://fish.com'
    assert asset.valid?
    assert_difference('Sop.count') do
      assert_difference('AssetLink.discussion.count') do
        asset.save!
      end
    end

  end

  test 'strip link before validate' do
    asset = FactoryBot.create(:sop)
    link = AssetLink.new(url:'  http://fish.com ', asset:asset)
    assert link.valid?
    assert_equal 'http://fish.com', link.url
  end

  test 'link_type' do
    # if this changes, then the database entries need updating
    assert_equal 'discussion', AssetLink::DISCUSSION

    link1 = FactoryBot.create(:discussion_link)
    link2 = FactoryBot.create(:asset_link, url:'http://google.com',link_type:'another')

    assert_equal [link1], AssetLink.discussion
  end


end