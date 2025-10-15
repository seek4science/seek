require 'test_helper'

class AvatarHelperTest < ActionView::TestCase
  include ImagesHelper
  include AvatarsHelper

  test 'renders default avatar if no avatar selected' do
    collection = FactoryBot.create(:public_collection)
    refute collection.avatar

    assert_equal '/images/avatars/avatar-collection.png',
                 img_src(avatar_according_to_user_upload('...', collection, 60))
  end

  test 'renders selected avatar if avatar selected' do
    collection = FactoryBot.create(:public_collection, :with_avatar)
    assert collection.avatar

    assert_equal "/collections/#{collection.id}/avatars/#{collection.avatar.id}?size=60x60",
                 img_src(avatar_according_to_user_upload('...', collection, 60))
  end

  test 'renders default avatar if avatar from another item selected' do
    person = FactoryBot.create(:person, :with_avatar)
    collection = FactoryBot.create(:public_collection, contributor: person)
    assert person.avatar
    collection.update_column(:avatar_id, person.avatar_id)
    assert_equal person.avatar, collection.reload.avatar

    # Only raises in dev/test - will show default avatar in production.
    assert_raises(RuntimeError, 'Avatar does not belong to instance') do
      assert_equal '/images/avatars/avatar-collection.png',
                   img_src(avatar_according_to_user_upload('...', collection, 60))
    end
  end

  def img_src(tag)
    tag.match(/src="([^"]+)"/)&.captures&.first
  end
end
