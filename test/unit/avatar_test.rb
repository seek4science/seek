require 'test_helper'
require 'storage_stub_helper'

class AvatarTest < ActiveSupport::TestCase
  include StorageStubHelper

  test 'requires owner' do
    avatar = Avatar.new(image_file: File.open("#{Rails.root}/test/fixtures/files/file_picture.png", 'rb'))
    refute avatar.valid?
    avatar.owner = FactoryBot.create :project
    assert avatar.valid?
  end

  test 'special flag to skip owner validation' do
    avatar = Avatar.new(image_file: File.open("#{Rails.root}/test/fixtures/files/file_picture.png", 'rb'))
    refute avatar.skip_owner_validation
    refute avatar.valid?

    avatar = Avatar.new(image_file: File.open("#{Rails.root}/test/fixtures/files/file_picture.png", 'rb'), skip_owner_validation: true)
    assert avatar.skip_owner_validation
    assert avatar.valid?
  end

  # on the S3 backend the master avatar image is stored through the storage
  # adapter, not just on local disk — so it survives on a node that never wrote it.
  test 'master image is stored via the adapter on S3' do
    png_path = "#{Rails.root}/test/fixtures/files/file_picture.png"
    png_bytes = File.binread(png_path)
    owner = FactoryBot.create(:project)

    with_stubbed_s3_storage do |dat, _converted|
      client = s3_client(dat)
      client.stub_responses(:head_object, content_length: png_bytes.bytesize)
      client.stub_responses(:get_object, body: png_bytes)

      avatar = Avatar.new(owner: owner, image_file: File.open(png_path, 'rb'))
      assert avatar.save, avatar.errors.full_messages.join(', ')
      assert avatar.remote_storage?, 'expected the S3 (remote) backend in this test'

      # The master was uploaded to the adapter and the local copy removed.
      assert_not File.exist?(avatar.send(:local_master_path)),
                 'local master should be removed after upload to S3'

      # A fresh instance (no in-memory image) must still see the master via the adapter,
      # and resizing must stream it back from the adapter and cache it locally.
      reloaded = Avatar.find(avatar.id)
      assert reloaded.has_saved_image?, 'avatar should report a saved image via the adapter on S3'

      FileUtils.rm_f(reloaded.full_cache_path('200x200'))
      assert_nothing_raised { reloaded.resize_image('200x200') }
      assert File.exist?(reloaded.full_cache_path('200x200')),
             'resized image should be cached locally after streaming the master from S3'
    end
  end
end
