require 'test_helper'

class DataFileTest < ActiveSupport::TestCase

  fixtures :all

  test "associations" do
    datafile=data_files(:picture)
    assert_equal users(:datafile_owner),datafile.contributor    

    blob=content_blobs(:picture_blob)
    assert_equal blob,datafile.content_blob
  end

  test "event association" do
    User.with_current_user Factory(:user) do
      datafile = Factory :data_file, :contributor => User.current_user
      event = Factory :event, :contributor => User.current_user
      datafile.events << event
      assert datafile.valid?
      assert datafile.save
      assert_equal 1, datafile.events.count
    end
  end

  test "assay association" do
    User.with_current_user Factory(:user) do
      datafile = data_files(:picture)
      assay = assays(:modelling_assay_with_data_and_relationship)
      relationship = relationship_types(:validation_data)
      assay_asset = assay_assets(:metabolomics_assay_asset1)
      assert_not_equal assay_asset.asset, datafile
      assert_not_equal assay_asset.assay, assay
      assay_asset.asset = datafile
      assay_asset.assay = assay
      assay_asset.relationship_type = relationship
      assay_asset.save!
      assay_asset.reload

      assert assay_asset.valid?
      assert_equal assay_asset.asset, datafile
      assert_equal assay_asset.assay, assay
      assert_equal assay_asset.relationship_type, relationship
    end
  end

  test "sort by updated_at" do
    assert_equal DataFile.find(:all).sort_by { |df| df.updated_at.to_i * -1 }, DataFile.find(:all)
  end

  test "validation" do
    asset=DataFile.new :title=>"fred",:projects=>[projects(:sysmo_project)]
    assert asset.valid?

    asset=DataFile.new :projects=>[projects(:sysmo_project)]
    assert !asset.valid?

    asset=DataFile.new :title=>"fred"
    assert !asset.valid?

    asset = DataFile.new :title => "fred", :projects => []
    assert !asset.valid?
  end

  def test_avatar_key
    assert_nil data_files(:picture).avatar_key
    assert data_files(:picture).use_mime_type_for_avatar?

    assert_nil data_file_versions(:picture_v1).avatar_key
    assert data_file_versions(:picture_v1).use_mime_type_for_avatar?
  end

  test "projects" do
    df=data_files(:sysmo_data_file)
    p=projects(:sysmo_project)
    assert_equal [p],df.projects
    assert_equal [p],df.latest_version.projects
  end
  
  def test_defaults_to_private_policy
    df_hash = Factory.attributes_for(:data_file)
    df_hash[:policy] = nil
    df=DataFile.new(df_hash)
    df.save!
    df.reload
    assert_not_nil df.policy
    assert_equal Policy::PRIVATE, df.policy.sharing_scope
    assert_equal Policy::NO_ACCESS, df.policy.access_type
    assert_equal false,df.policy.use_whitelist
    assert_equal false,df.policy.use_blacklist
    assert df.policy.permissions.empty?
  end

  test "data_file with no contributor" do
    df=data_files(:data_file_with_no_contributor)
    assert_nil df.contributor
  end

  test "versions destroyed as dependent" do
    df=data_files(:sysmo_data_file)
    User.current_user = df.contributor
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
    User.current_user = df.contributor
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
    User.current_user = df.contributor
    assert_difference("DataFile.count",-1) do
      df.destroy
    end
    assert_nil DataFile.find_by_id(df.id)
    assert_difference("DataFile.count",1) do
      disable_authorization_checks {DataFile.restore_trash!(df.id)}
    end
    assert_not_nil DataFile.find_by_id(df.id)
  end

  test 'failing to delete due to can_delete does not create trash' do
    df = Factory :data_file, :policy => Factory(:private_policy), :contributor => Factory(:user)
    User.with_current_user Factory(:user) do
      assert_no_difference("DataFile.count") do
        df.destroy
      end
      assert_nil DataFile.restore_trash(df.id)
    end
  end
  
  test "test uuid generated" do
    x = data_files(:picture)
    assert_nil x.attributes["uuid"]
    x.save
    assert_not_nil x.attributes["uuid"]
  end
  
  test "title_trimmed" do
    df=data_files(:picture)
    df.title=" should be trimmed"
    df.save!
    assert_equal "should be trimmed",df.title
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

  test "delete checks authorization" do
    df = Factory :data_file

    User.current_user = nil
    assert !df.destroy

    User.current_user = df.contributor
    assert df.destroy
  end

  test 'update checks authorization' do
    unupdated_title = "Unupdated Title"
    df = Factory :data_file, :title => unupdated_title
    User.current_user = nil

    assert !df.update_attributes(:title => "Updated Title")
    assert_equal unupdated_title, df.reload.title
  end

  test "convert to presentation" do
    user = Factory :user
    data_file = Factory :data_file,:contributor=>user
    presentation = Factory.build :presentation,:contributor=>user
    data_file_converted = data_file.convert_to_presentation

    assert_equal "Presentation", data_file_converted.class.name
    assert_equal presentation.attributes.keys, data_file_converted.attributes.keys
    assert data_file_converted.valid?

    data_file_converted.save!
    data_file_converted.reload

    assert_equal data_file.policy.sharing_scope, data_file_converted.policy.sharing_scope
    assert_equal data_file.policy.access_type, data_file_converted.policy.access_type
    assert_equal data_file.policy.use_whitelist, data_file_converted.policy.use_whitelist
    assert_equal data_file.policy.use_blacklist, data_file_converted.policy.use_blacklist
    assert_equal data_file.policy.permissions, data_file_converted.policy.permissions

    assert_equal data_file.event_ids, data_file_converted.event_ids
    assert_equal data_file.creators, data_file_converted.creators

  end
end
