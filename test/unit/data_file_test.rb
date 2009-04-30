require 'test_helper'

class DataFileTest < ActiveSupport::TestCase

  fixtures :data_files,:users,:people,:content_blobs

  # Replace this with your real tests.
  test "associations" do
    datafile=data_files(:picture)
    assert_equal users(:datafile_owner),datafile.contributor    

    blob=content_blobs(:picture_blob)
    assert_equal blob,datafile.content_blob
    
  end
end
