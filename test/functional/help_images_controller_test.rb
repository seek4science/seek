require 'test_helper'
require 'storage_stub_helper'

class HelpImagesControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper
  include StorageStubHelper

  def setup
    login_as(:quentin)
  end

  test 'should upload image' do
    with_config_value :internal_help_enabled, true do
      assert_difference('HelpImage.count', 1) do
        post :create, xhr: true, params: { help_document_id: help_documents(:one).identifier,
                                           content_blobs: [{ data: picture_file }] }
        assert_response :success
        assert_empty assigns(:error_text)
      end
    end
  end

  test 'should not upload text' do
    with_config_value :internal_help_enabled, true do
      assert_no_difference('HelpImage.count') do
        post :create, xhr: true, params: { help_document_id: help_documents(:one).identifier,
                                           content_blobs: [{ data: file_for_upload }] }
        assert_response :bad_request
        assert_not_empty assigns(:error_text)
        assert assigns(:error_text).any? { |e| e.include?('Not an image') }
      end
    end
  end

  test 'should delete image' do
    with_config_value :internal_help_enabled, true do
      image = help_documents(:one).images.create!(content_blob: FactoryBot.create(:image_content_blob))
      assert_difference('HelpImage.count', -1) do
        delete :destroy, xhr: true, params: { id: image.id }
        assert_response :success
      end
    end
  end

  test 'should view image' do
    with_config_value :internal_help_enabled, true do
      image = help_documents(:one).images.create!(content_blob: FactoryBot.create(:image_content_blob))
      get :view, params: { id: image.id }
      assert_response :success
    end
  end

  test 'should redirect to presigned URL when viewing full-size image on S3 backend' do
    with_config_value :internal_help_enabled, true do
      image = help_documents(:one).images.create!(content_blob: FactoryBot.create(:image_content_blob))
      with_stubbed_s3_storage do
        get :view, params: { id: image.id }
        assert_response :redirect
        assert_match(/test-bucket/, @response.location)
        assert_match(/#{image.content_blob.uuid}\.dat/, @response.location)
      end
    end
  end

  test 'should serve resized image on S3 backend by streaming the original for the resize' do
    with_config_value :internal_help_enabled, true do
      image = help_documents(:one).images.create!(content_blob: FactoryBot.create(:image_content_blob))
      blob = image.content_blob
      original_bytes = File.binread(blob.filepath)
      FileUtils.rm_f(blob.full_cache_path('300'))
      with_stubbed_s3_storage do |dat, _converted|
        s3_client(dat).stub_responses(:head_object, content_length: original_bytes.bytesize)
        s3_client(dat).stub_responses(:get_object, body: original_bytes)
        # The resize uses ContentBlob#resize_image, which streams the original from S3,
        # caches the resized result locally, and serves it.
        get :view, params: { id: image.id, image_size: '300' }
        assert_response :success
      end
    ensure
      FileUtils.rm_f(blob.full_cache_path('300')) if blob
    end
  end

  private

  def picture_file
    fixture_file_upload('file_picture.png', 'image/png')
  end
end
