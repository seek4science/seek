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

end
