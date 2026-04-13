require 'test_helper'

class ContentBlobApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite

  def private_resource
    @p ||= FactoryBot.create(:min_content_blob, asset: FactoryBot.create(:private_document))
  end

  def skip_index_test?
    true
  end

  def setup
    user_login
    @content_blob = FactoryBot.create(:min_content_blob)
    @sop = @content_blob.asset
  end

  test 'update content blob data' do
    sop = FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy),
                            contributor: @current_user.person,
                            content_blob: FactoryBot.create(:content_blob, data: nil))
    blob = sop.content_blob
    assert blob.no_content?
    new_data = 'X'*123

    assert sop.can_edit?
    put polymorphic_url([sop, blob]), params: new_data, headers: {'Content-Type': 'application/octet-stream'}
    assert_response :success
    assert_equal '123', response.body
    blob.reload
    assert_equal new_data, blob.data_io_object.read
    assert_equal '28488119a9628c90674ccb5353330f42', blob.md5sum

    # now try with an UploadFile
    sop = FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy),
                            contributor: @current_user.person,
                            content_blob: FactoryBot.create(:content_blob, data: nil))
    blob = sop.content_blob
    assert blob.no_content?

    assert sop.can_edit?
    put polymorphic_url([sop, blob]), params: fixture_file_upload('a_pdf_file.pdf', 'application/pdf'), headers: {'Content-Type': 'application/octet-stream'}
    assert_response :success
    assert_equal '8827', response.body

    blob.reload
    assert_equal 8827, blob.data_io_object.size
    assert_equal '565ae8a7a743c3bfd9f15c69647f5b8b', blob.md5sum

  end

  private

  def collection_url
    polymorphic_url([@sop, :content_blobs], format: :json)
  end

  def member_url(res)
    asset = res.is_a?(ContentBlob) ? res.asset : @sop
    polymorphic_url([asset, res], format: :json)
  end
end
