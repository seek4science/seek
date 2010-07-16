require File.dirname(__FILE__) + '/../test_helper'

class DataFileTest < ActiveSupport::TestCase

  fixtures :all

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
    assert_equal p,df.project
    assert_equal p,df.latest_version.project
  end

  test "data_file with no contributor" do
    df=data_files(:data_file_with_no_contributor)
    assert_nil df.contributor
  end

  test "versions destroyed as dependent" do
    df=data_files(:sysmo_data_file)
    assert_equal 1,df.versions.size,"There should be 1 version of this DataFile"
    assert_difference(["DataFile.count","DataFile::Version.count"],-1) do
      df.destroy
    end
  end

  test "managers" do
    df=data_files(:picture)
    assert_not_nil df.managers
    contributor=people(:person_for_datafile_owner)
    manager=people(:person_for_owner_of_my_first_sop)
    assert df.managers.include?(contributor)
    assert df.managers.include?(manager)
    assert !df.managers.include?(people(:person_not_associated_with_any_projects))
  end

  test "make sure content blob is preserved after deletion" do
    df = data_files(:picture)
    assert_not_nil df.content_blob,"Must have an associated content blob for this test to work"
    cb=df.content_blob
    assert_difference("DataFile.count",-1) do
      assert_no_difference("ContentBlob.count") do
        df.destroy
      end
    end
    assert_not_nil ContentBlob.find(cb.id)
  end

  test "is restorable after destroy" do
    df = data_files(:picture)
    assert_difference("DataFile.count",-1) do
      df.destroy
    end
    assert_nil DataFile.find_by_id(df.id)
    assert_difference("DataFile.count",1) do
      DataFile.restore_trash!(df.id)
    end
    assert_not_nil DataFile.find_by_id(df.id)
  end
  
  test "test uuid generated" do
    x = data_files(:picture)
    assert_nil x.attributes["uuid"]
    x.save
    assert_not_nil x.attributes["uuid"]
  end

  test "uuid doesn't change" do
    x = data_files(:picture)
    x.save
    uuid = x.attributes["uuid"]
    x.save
    assert_equal x.uuid, uuid
  end
  
  test "can get relationship type" do
    df = data_file_versions(:picture_v1)
    assay = assays(:modelling_assay_with_data_and_relationship)
    assert_equal relationship_types(:validation_data), df.relationship_type(assay)
  end
end
