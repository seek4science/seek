require 'test_helper'

class HelpImagesControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper

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

  private

  def picture_file
    fixture_file_upload('file_picture.png', 'image/png')
  end
end
