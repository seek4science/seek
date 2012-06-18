require 'test_helper'

class DataFileTest < ActiveSupport::TestCase

  fixtures :all

  test "associations" do
    datafile=data_files(:picture)
    assert_equal users(:datafile_owner),datafile.contributor

    blob=content_blobs(:picture_blob)
    assert_equal blob,datafile.content_blob
  end

  test "spreadsheet contents for search" do
    df = Factory :rightfield_datafile
    
    data = df.spreadsheet_contents_for_search
    assert !data.empty?,"Content should not be empty"
    assert data.include?("design type")
    assert data.include?("methodological design"), "content should be humanized"
    assert data.include?("MethodologicalDesign"),"should also preserve original form before humanizing"
    assert data.include?("absolute")
    assert !data.include?("ontology"),"Shouldn't include content from hidden sheets"
    assert !data.include?("relative"),"Shouldn't include content from hidden sheets"

    assert !data.include?("44.0"),"Should not include numbers"
    assert !data.include?("1.0"),"Should not include numbers"
    assert !data.include?("1.7"),"Should not include numbers"

    assert !data.include?(44),"Should not include numbers"
    assert !data.include?(1),"Should not include numbers"
    assert !data.include?(1.7),"Should not include numbers"

    assert !data.include?("seek id"),"Should not include blacklisted text"

    df = data_files(:picture)
    assert_equal [],df.spreadsheet_contents_for_search
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
    x = data_files(:private_data_file)
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
    User.with_current_user(user) {
      data_file = Factory :data_file,:contributor=>user
      presentation = Factory.build :presentation,:contributor=>user
      data_file_converted = data_file.convert_to_presentation

      assert_equal "Presentation", data_file_converted.class.name
      assert_equal presentation.attributes.keys.sort!, data_file_converted.attributes.keys.reject{|k|k=='id'}.sort!

      data_file_converted.valid?
      assert data_file_converted.valid?

      data_file_converted.save!
      data_file_converted.reload

      assert_equal data_file.policy.sharing_scope, data_file_converted.policy.sharing_scope
      assert_equal data_file.policy.access_type, data_file_converted.policy.access_type
      assert_equal data_file.policy.use_whitelist, data_file_converted.policy.use_whitelist
      assert_equal data_file.policy.use_blacklist, data_file_converted.policy.use_blacklist
      assert_equal data_file.policy.permissions, data_file_converted.policy.permissions

      assert_equal data_file.subscriptions.map(&:person_id), data_file_converted.subscriptions(&:person_id)
      assert_equal data_file.event_ids, data_file_converted.event_ids
      assert_equal data_file.creators, data_file_converted.creators
      assert_equal data_file.project_ids,data_file_converted.project_ids
    }
  end

  test 'should convert tag from datafile to presentation' do
      user = Factory :user
      User.with_current_user(user) {
        data_file = Factory :data_file,:contributor=>user
        Factory :tag,:annotatable=>data_file,:source=>user,:value=>"fish"

        assert_equal 1, data_file.annotations.count
        assert_equal 0, data_file.annotations.first.versions.count
        assert 'fish', data_file.annotations.first.value.text

        data_file_converted = data_file.convert_to_presentation
        data_file_converted.save!
        data_file_converted.reload
        data_file.reload

        assert [], data_file.annotations
        assert [], Annotation::Version.find(:all, :conditions => ['annotatable_type=? and annotatable_id=?', 'DataFile', data_file.id])
        assert_equal 1, data_file_converted.annotations.count
        assert_equal 0, data_file_converted.annotations.first.versions.count
        assert 'fish', data_file_converted.annotations.first.value.text
      }
  end

  test "fs_search_fields" do
    user = Factory :user
    User.with_current_user user do
      df = Factory :data_file,:contributor=>user
      sf1 = Factory :studied_factor_link,:substance=>Factory(:compound,:name=>"sugar")
      sf2 = Factory :studied_factor_link,:substance=>Factory(:compound,:name=>"iron")
      comp=sf2.substance
      Factory :synonym,:name=>"metal",:substance=>comp
      Factory :mapping_link,:substance=>comp,:mapping=>Factory(:mapping,:chebi_id=>"12345",:kegg_id=>"789",:sabiork_id=>111)
      studied_factor = Factory :studied_factor,:studied_factor_links=>[sf1,sf2],:data_file=>df
      assert df.fs_search_fields.include?("sugar")
      assert df.fs_search_fields.include?("metal")
      assert df.fs_search_fields.include?("iron")
      assert df.fs_search_fields.include?("concentration")
      assert df.fs_search_fields.include?("CHEBI:12345")
      assert df.fs_search_fields.include?("12345")
      assert df.fs_search_fields.include?("111")
      assert df.fs_search_fields.include?("789")
      assert_equal 8,df.fs_search_fields.count
    end
  end

  test "fs_search_fields_with_synonym_substance" do
    user = Factory :user
    User.with_current_user user do
      df = Factory :data_file,:contributor=>user
      suger = Factory(:compound,:name=>"sugar")
      iron = Factory(:compound,:name=>"iron")
      metal = Factory :synonym,:name=>"metal",:substance=>iron
      Factory :mapping_link,:substance=>iron,:mapping=>Factory(:mapping,:chebi_id=>"12345",:kegg_id=>"789",:sabiork_id=>111)

      sf1 = Factory :studied_factor_link,:substance=>suger
      sf2 = Factory :studied_factor_link, :substance=>metal

      Factory :studied_factor,:studied_factor_links=>[sf1,sf2],:data_file=>df
      assert df.fs_search_fields.include?("sugar")
      assert df.fs_search_fields.include?("metal")
      assert df.fs_search_fields.include?("iron")
      assert df.fs_search_fields.include?("concentration")
      assert df.fs_search_fields.include?("CHEBI:12345")
      assert df.fs_search_fields.include?("12345")
      assert df.fs_search_fields.include?("111")
      assert df.fs_search_fields.include?("789")
      assert_equal 8,df.fs_search_fields.count
    end
  end

  test "get treatments" do
      user = Factory :user
      User.with_current_user user do
        data=File.new("#{Rails.root}/test/fixtures/files/treatments-normal-case.xls","rb").read
        df = Factory :data_file,:contributor=>user,:content_type=>"application/excel",:content_blob=>Factory(:content_blob,:data=>data)
        assert_not_nil df.spreadsheet_xml
        assert df.is_excel?
        assert df.is_extractable_spreadsheet?
        assert_not_nil df.treatments
        assert_equal 2,df.treatments.values.keys.count
        assert_equal ["Dilution_rate","pH"],df.treatments.values.keys.sort

        data=File.new("#{Rails.root}/test/fixtures/files/file_picture.png","rb").read
        df = Factory :data_file,:contributor=>user,:content_blob=>Factory(:content_blob,:data=>data)
        assert_not_nil df.treatments
        assert_equal 0,df.treatments.values.keys.count
      end
  end

  test "is_xls" do
    df = Factory :rightfield_datafile
    assert df.is_xls?

    df = Factory :xlsx_spreadsheet_datafile
    assert !df.is_xls?
  end

end
