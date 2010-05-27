require 'test_helper'


class ContentBlobTest < ActiveSupport::TestCase
  fixtures :content_blobs
  def test_md5sum_on_demand
    blob=content_blobs(:picture_blob)
    assert_not_nil blob.md5sum
    assert_equal "2288e57a82162f5fd7fa7050ebadbcba",blob.md5sum
  end
  
  def test_uuid_doesnt_change
    blob=content_blobs(:picture_blob)
    assert_equal "zzz",blob.uuid
    blob.save!
    assert_equal "zzz",blob.uuid
  end
  
  def test_file_dump
    pic=content_blobs(:picture_blob)
    blob=ContentBlob.new(:data=>pic.data)
    blob.save!
    assert_not_nil blob.filepath
    data=nil
    File.open(blob.filepath,"rb") do |f|
      data=f.read
    end
    assert_not_nil data
    assert_equal test_data('file_picture.png'),data
  end
  
  def test_uuid
    pic=content_blobs(:picture_blob)
    blob=ContentBlob.new(:data=>pic.data)
    blob.save!
    assert_not_nil blob.uuid
    assert_not_nil ContentBlob.find(blob.id).uuid
  end
  
  def test_data filename
    file = "#{RAILS_ROOT}/test/fixtures/files/#{filename}"
    return File.open(file,"rb").read
  end
end
