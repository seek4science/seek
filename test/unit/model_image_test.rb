require 'test_helper'
require 'storage_stub_helper'

class ModelTest < ActiveSupport::TestCase
  include StorageStubHelper

  test 'default size' do
    assert_equal '200x200', ModelImage::DEFAULT_SIZE
  end

  test 'large size' do
    assert_equal '1000x1000', ModelImage::LARGE_SIZE
  end

  # Option A (Step 06): on the S3 backend the master model image is stored through the storage
  # adapter, not just on local disk — so it survives on a node that never wrote it.
  test 'master image is stored via the adapter on S3' do
    png_bytes = File.binread("#{Rails.root}/test/fixtures/files/file_picture.png")

    with_stubbed_s3_storage do |dat, _converted|
      client = s3_client(dat)
      client.stub_responses(:head_object, content_length: png_bytes.bytesize)
      client.stub_responses(:get_object, body: png_bytes)

      model = FactoryBot.create(:model)
      model_image = FactoryBot.create(:model_image, model: model)
      assert model_image.remote_storage?, 'expected the S3 (remote) backend in this test'

      # The master was uploaded to the adapter and the local copy removed.
      assert_not File.exist?(model_image.send(:local_master_path)),
                 'local master should be removed after upload to S3'

      # A fresh instance (no in-memory image) must still see the master via the adapter,
      # and resizing must stream it back from the adapter and cache it locally.
      reloaded = ModelImage.find(model_image.id)
      assert reloaded.has_saved_image?, 'model image should report a saved image via the adapter on S3'

      FileUtils.rm_f(reloaded.full_cache_path('200x200'))
      assert_nothing_raised { reloaded.resize_image('200x200') }
      assert File.exist?(reloaded.full_cache_path('200x200')),
             'resized image should be cached locally after streaming the master from S3'
    end
  end
end
