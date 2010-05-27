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
    blob.uuid="zzz"
    assert_equal "zzz",blob.uuid
    blob.save!
    assert_equal "zzz",blob.uuid
  end
  
  def test_uuid_doesnt_change2
    blob=content_blobs(:picture_blob)
    blob.uuid="zzz"
    blob.save!
    blob=ContentBlob.find(blob.id)
    assert_equal "zzz",blob.uuid
    blob.save!
    blob=ContentBlob.find(blob.id)
    assert_equal "zzz",blob.uuid
  end
  
  def test_regenerate_uuid
    pic=content_blobs(:picture_blob)
    uuid=pic.uuid
    pic.regenerate_uuid
    assert_not_equal uuid,pic.uuid    
  end
  
  def test_file_dump
    pic=content_blobs(:picture_blob)
    blob=ContentBlob.new(:data_old=>pic.data)
    blob.save!
    assert_not_nil blob.filepath
    data=nil
    File.open(blob.filepath,"rb") do |f|
      data=f.read
    end
    assert_not_nil data
    assert_equal test_data('file_picture.png'),data
  end
  
  def test_dumps_file_on_fetch
    pic=content_blobs(:picture_blob)
    pic.regenerate_uuid #makes sure is not there from a previous test
    assert !pic.file_exists?
    assert_equal test_data('file_picture.png'),pic.data
    assert pic.file_exists?
    assert_equal test_data('file_picture.png'),pic.data
  end
  
  #checks that the data is assigned through the new method, stored to a file, and not written to the old data_old field
  def test_data_assignment
    pic=content_blobs(:picture_blob)
    blob=ContentBlob.new(:data=>pic.data)
    blob.save!
    blob=ContentBlob.find(blob.id)
    assert_nil blob.data_old
    assert_equal test_data('file_picture.png'),blob.data
    
    assert_not_nil blob.filepath
    data=nil
    File.open(blob.filepath,"rb") do |f|
      data=f.read
    end
    assert_not_nil data
    assert_equal test_data('file_picture.png'),data
  end
  
  def test_file_exists
    pic=content_blobs(:picture_blob)    
    pic.regenerate_uuid #makes sure is not there from a previous test
    assert !pic.file_exists?
    pic.save!
    assert pic.file_exists?
  end
  
  #simply checks that get and set data returns the same thing
  def test_data_assignment2
    pic=content_blobs(:picture_blob)
    pic.data=test_data("little_file.txt")
    assert_equal test_data("little_file.txt"),pic.data
  end
  
  def test_will_overwrite_if_data_changes
    pic=content_blobs(:picture_blob)
    pic.save!
    assert_equal test_data("file_picture.png"),File.open(pic.filepath,"rb").read
    pic.data=test_data("little_file.txt")
    pic.save!
    assert_equal test_data("little_file.txt"),File.open(pic.filepath,"rb").read
  end
  
  def test_uuid
    pic=content_blobs(:picture_blob)
    blob=ContentBlob.new(:data_old=>pic.data)
    blob.save!
    assert_not_nil blob.uuid
    assert_not_nil ContentBlob.find(blob.id).uuid
  end
  
  def test_data filename
    file = "#{RAILS_ROOT}/test/fixtures/files/#{filename}"
    return File.open(file,"rb").read
  end
end
