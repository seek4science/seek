require 'test_helper'

class ContentBlobApiTest < ActionDispatch::IntegrationTest
  include ReadApiTestSuite

  def model
    ContentBlob
  end

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
    "/sops/#{@sop.id}/content_blobs.json"
  end

  def member_url(res)
    if res.is_a?(Numeric)
      id = res
      asset = @sop
    else
      id = res.id
      asset = res.asset
    end
    "/#{asset.model_name.collection}/#{asset.id}/content_blobs/#{id}.json"
  end
end
