require 'test_helper'
require 'openbis_test_helper'

class SeekUtilTest < ActiveSupport::TestCase
  fixtures :studies

  def setup
    mock_openbis_calls
    @endpoint = Factory(:openbis_endpoint)
    @util = Seek::Openbis::SeekUtil.new
    @study = studies(:junk_study)
    @zample = Seek::Openbis::Zample.new(@endpoint, '20171002172111346-37')
    @creator = Factory(:person)
  end

  test 'setup work' do
    assert @util
    assert @study
    assert  @zample
    assert @creator
  end

  test 'creates valid study with external_asset that can be saved' do

    investigation = Factory(:investigation)
    assert investigation.save

    params = { investigation_id: investigation.id}
    sync_options = {link_datasets: '1', link_assays: '1'}

    experiment = Seek::Openbis::Experiment.new(@endpoint, '20171121152132641-51')

    asset = OpenbisExternalAsset.build(experiment, sync_options)

    study = @util.createObisStudy(params, @creator,asset)

    assert study.valid?


    assert_difference('Study.count') do
      assert_difference('ExternalAsset.count') do
        study.save!
      end
    end


    assert_equal "OpenBIS #{experiment.perm_id}", study.title
    assert_equal @creator, study.contributor
    assert_same asset, study.external_asset
    assert_equal investigation, study.investigation
  end

  test 'creates valid assay with dependent external_asset that can be saved' do

    params = { study_id: @study.id}
    sync_options = {link_datasets: '1'}

    asset = OpenbisExternalAsset.build(@zample, sync_options)

    assay = @util.createObisAssay(params, @creator,asset)

    assert assay.valid?

    assert_difference('Assay.count') do
      assert_difference('ExternalAsset.count') do
        assay.save!
      end
    end


    assert_equal "OpenBIS #{@zample.perm_id}", assay.title
    assert_equal @creator, assay.contributor
    assert_same asset, assay.external_asset
  end

  test 'creates valid datafile with dependent external_assed that can be saved' do
    dataset = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')
    assert dataset

    asset = OpenbisExternalAsset.build(dataset)

    df = @util.createObisDataFile(asset)

    assert df.valid?

    assert_difference('DataFile.count') do
      assert_difference('ExternalAsset.count') do
        df.save!
      end
    end
  end

  test 'should_follow_depended gives false on datafile or nil' do

    dataset = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')
    asset = OpenbisExternalAsset.build(dataset)

    refute @util.should_follow_dependent(asset)

    asset.seek_entity = Factory :data_file
    assert asset.seek_entity

    refute @util.should_follow_dependent(asset)

  end

  test 'should_follow gives true if link_datasets selected' do

    sync_options = {link_datasets: '1'}
    asset = OpenbisExternalAsset.build(@zample, sync_options)

    asset.seek_entity = Factory :assay

    assert @util.should_follow_dependent(asset)

    asset.sync_options = {}
    refute @util.should_follow_dependent(asset)

  end

  test 'fetch_current_entity_version fetches entity' do
    asset = OpenbisExternalAsset.build(@zample)

    entity = @util.fetch_current_entity_version(asset)
    assert entity
    assert_equal @zample, entity

    asset.external_id = "XXX"
    assert_raises Exception do
      assert @util.fetch_current_entity_version(asset)
    end
  end

  test 'sync_external_asset refreshes content and set sync status' do

    dataset1 = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')
    dataset2 = Seek::Openbis::Dataset.new(@endpoint, '20160215111736723-31')

    asset = OpenbisExternalAsset.build(dataset1)
    asset.synchronized_at = DateTime.now - 1.days
    asset.external_id = dataset2.perm_id

    assert_not_equal dataset2.perm_id, asset.content.perm_id

    asset.sync_state = :refresh
    assert asset.save

    refute asset.synchronized?
    @util.sync_external_asset(asset)

    asset.reload

    assert asset.synchronized?
    assert_equal DateTime.now.to_date, asset.synchronized_at.to_date

    assert_equal dataset2.perm_id, asset.content.perm_id
  end

  test 'sync_external_asset links datasets to assay if follow links' do

    refute @zample.dataset_ids.empty?

    assay = Factory :assay

    assert assay.data_files.empty?

    asset = OpenbisExternalAsset.build(@zample)
    asset.sync_options = {link_datasets: '1'}
    asset.sync_state = :refresh
    asset.seek_entity = assay

    @util.sync_external_asset(asset)

    assert asset.synchronized?
    refute assay.data_files.empty?
    assert_equal @zample.dataset_ids.length, assay.data_files.length

  end

  test 'sync_external_asset does not link datasets to assay if sync_options not set' do

    refute @zample.dataset_ids.empty?

    assay = Factory :assay

    assert assay.data_files.empty?

    asset = OpenbisExternalAsset.build(@zample)
    asset.sync_options = {link_datasets: '0'}
    asset.sync_state = :refresh
    asset.seek_entity = assay

    @util.sync_external_asset(asset)

    assert asset.synchronized?
    assert assay.data_files.empty?

  end


  test 'associate_data_sets links datasets with assay creating new datafiles if necessary' do


    assay = Factory :assay

    df0 = Factory :data_file
    assay.associate(df0)
    assert df0.persisted?
    assert_equal 1, assay.data_files.length


    datasets = Seek::Openbis::Dataset.new(@endpoint).find_by_perm_ids(["20171002172401546-38", "20171002190934144-40", "20171004182824553-41"])
    assert_equal 3, datasets.length

    df1 = @util.createObisDataFile(OpenbisExternalAsset.build(datasets[0]))
    assert df1.save

    assert_difference('AssayAsset.count', 3) do
      assert_difference('DataFile.count', 2) do
        assert_difference('ExternalAsset.count', 2) do

          assert_nil @util.associate_data_sets(assay, datasets)
        end
      end
    end

    assay.reload
    assert_equal 4, assay.data_files.length

  end

  test 'associate_data_sets_ids links datasets with assay creating new datafiles if necessary' do


    assay = Factory :assay

    df0 = Factory :data_file
    assay.associate(df0)
    assert df0.persisted?
    assert_equal 1, assay.data_files.length

    data_sets_ids = ["20171002172401546-38", "20171002190934144-40", "20171004182824553-41"]

    assert_difference('AssayAsset.count', 3) do
      assert_difference('DataFile.count', 3) do
        assert_difference('ExternalAsset.count', 3) do

          assert_nil @util.associate_data_sets_ids(assay, data_sets_ids, @endpoint)
        end
      end
    end

    assay.reload
    assert_equal 4, assay.data_files.length

  end

  test 'associate_zamples_as_assays links zamples as new assays with study' do


    study = Factory :study

    assert study.assays.empty?

    zamples = Seek::Openbis::Zample.new(@endpoint).find_by_perm_ids(['20171002172111346-37', '20171002172639055-39'])
    assert_equal 2, zamples.length

    sync_options = {}

    assert_difference('Assay.count', 2) do
      assert_difference('AssayAsset.count', 0) do
        assert_difference('DataFile.count', 0) do
          assert_difference('ExternalAsset.count', 2) do

          assert_equal [], @util.associate_zamples_as_assays(study, zamples, sync_options)
          end
        end
      end
    end


    study.reload
    assert_equal 2, study.assays.count

  end

  test 'associate_zamples_as_assays reports issues if zample already registered but not as assay' do


    study = Factory :study

    assert study.assays.empty?

    zamples = Seek::Openbis::Zample.new(@endpoint).find_by_perm_ids(['20171002172111346-37', '20171002172639055-39'])
    assert_equal 2, zamples.length

    df = Factory :data_file
    ea = OpenbisExternalAsset.find_or_create_by_entity(zamples[0])
    df.external_asset = ea
    assert df.save
    assert ea.save

    sync_options = {}
    issues = []
    assert_difference('Assay.count', 1) do
      assert_difference('AssayAsset.count', 0) do
        assert_difference('DataFile.count', 0) do
          assert_difference('ExternalAsset.count', 1) do

            issues =@util.associate_zamples_as_assays(study, zamples, sync_options)
          end
        end
      end
    end

    refute issues.empty?
    study.reload
    assert_equal 1, study.assays.count

  end

  test 'associate_zamples_as_assays reports issues if zample already registered under different study' do


    study = Factory :study

    assert study.assays.empty?

    zamples = Seek::Openbis::Zample.new(@endpoint).find_by_perm_ids(['20171002172111346-37', '20171002172639055-39'])
    assert_equal 2, zamples.length

    study2 = Factory :study
    assay2 = Factory :assay
    assay2.study = study2

    ea = OpenbisExternalAsset.find_or_create_by_entity(zamples[0])
    assay2.external_asset = ea
    assert_equal study2, assay2.study

    assay2.valid?
    puts assay2.errors.full_messages

    disable_authorization_checks do
      assert assay2.save
      assert ea.save
    end

    sync_options = {}
    issues = []
    assert_difference('Assay.count', 1) do
      assert_difference('AssayAsset.count', 0) do
        assert_difference('DataFile.count', 0) do
          assert_difference('ExternalAsset.count', 1) do

            issues =@util.associate_zamples_as_assays(study, zamples, sync_options)
          end
        end
      end
    end

    refute issues.empty?
    study.reload
    assert_equal 1, study.assays.count

    study2.reload
    assay2.reload
    assert_equal study2, assay2.study


  end

  test 'follow_dependent links datasets' do

    refute @zample.dataset_ids.empty?

    assay = Factory :assay

    assert assay.data_files.empty?

    asset = OpenbisExternalAsset.build(@zample)
    asset.seek_entity = assay

    errs  = @util.follow_dependent(asset,@zample)
    refute errs

    refute assay.data_files.empty?
    assert_equal @zample.dataset_ids.length, assay.data_files.length

  end

  test 'fetch_current_entity_version gets fresh version ignoring cache' do

    dataset1 = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')

    dj = dataset1.json
    dj['code']='123'
    val = {'datasets' => [dj]}

    assert_not_equal '123', dataset1.code

    explicit_query_mock
    set_mocked_value_for_id('20160210130454955-23',val)

    dataset1 = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')
    assert_not_equal '123', dataset1.code

    asset = OpenbisExternalAsset.build(dataset1)
    dataset2 = @util.fetch_current_entity_version(asset)
    assert_equal '123', dataset2.code
  end

  test 'assay_types gives types annotated as assay' do
    types = @util.assay_types(@endpoint)
    assert types
    codes = types.map {|t| t.code}
    assert_equal ['TZ_ASSAY', 'UNKNOWN'], codes
  end

  test 'dataset_types gives all dataset types' do
    types = @util.dataset_types(@endpoint)
    assert types
    codes = types.map {|t| t.code}
    assert_equal 7, codes.size
    assert_includes codes, 'TZ_FAIR'
  end
end
