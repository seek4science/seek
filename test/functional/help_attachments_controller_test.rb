require 'test_helper'

class HelpAttachmentsControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  def setup
    login_as(:quentin)
  end

  test 'should upload attachment' do
    with_config_value :internal_help_enabled, true do
      assert_difference('HelpAttachment.count', 1) do
        post :create, xhr: true, params: { help_document_id: help_documents(:one).identifier,
                                           help_attachment: { title: 'New Attachment XYZ' },
                                           content_blobs: [{ data: file_for_upload }] }
        assert_response :success
        assert_includes @response.body, 'New Attachment XYZ'
        assert_empty assigns(:error_text)
      end
    end
  end

  test 'should delete attachment' do
    with_config_value :internal_help_enabled, true do
      attachment = help_documents(:one).attachments.create!(content_blob: FactoryBot.create(:pdf_content_blob))
      assert_difference('HelpAttachment.count', -1) do
        delete :destroy, xhr: true, params: { id: attachment.id }
        assert_response :success
      end
    end
  end

  test 'should download attachment' do
    with_config_value :internal_help_enabled, true do
      attachment = help_documents(:one).attachments.create!(content_blob: FactoryBot.create(:pdf_content_blob))
      get :download, params: { id: attachment.id }
      assert_response :success
    end
  end
end
