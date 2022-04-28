require 'test_helper'

class ContentBlobApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite

  def private_resource
    @p ||= Factory(:min_content_blob, asset: Factory(:private_document))
  end

  def skip_index_test?
    true
  end

  def setup
    admin_login
    @content_blob = Factory(:min_content_blob)
    @sop = @content_blob.asset
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
