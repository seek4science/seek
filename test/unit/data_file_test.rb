require File.dirname(__FILE__) + '/../test_helper'

class DataFileTest < ActiveSupport::TestCase

  fixtures :data_files,:users,:people,:content_blobs,:assets,:projects

  # Replace this with your real tests.
  test "associations" do
    datafile=data_files(:picture)
    assert_equal users(:datafile_owner),datafile.contributor    

    blob=content_blobs(:picture_blob)
    assert_equal blob,datafile.content_blob
    
  end

  test "project" do
    df=data_files(:sysmo_data_file)
    p=projects(:sysmo_project)
    assert_equal p,df.asset.project
    assert_equal p,df.project
    assert_equal p,df.latest_version.asset.project
    assert_equal p,df.latest_version.project
  end
end
