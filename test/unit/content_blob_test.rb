require 'test_helper'


class ContentBlobTest < ActiveSupport::TestCase
  fixtures :content_blobs
  def test_md5sum_on_demand
    blob=content_blobs(:picture_blob)
    assert_not_nil blob.md5sum
    assert_equal "2288e57a82162f5fd7fa7050ebadbcba",blob.md5sum
  end
  
  def test_uuid
    pic=content_blobs(:picture_blob)
    blob=ContentBlob.new(:data=>pic.data)
    blob.save!
    assert_not_nil blob.uuid
    assert_not_nil ContentBlob.find(blob.id).uuid
  end
end
