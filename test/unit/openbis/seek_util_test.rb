require 'test_helper'
require 'openbis_test_helper'

class SeekUtilTest < ActiveSupport::TestCase

  def setup
    FactoryBot.create :experimental_assay_class
    mock_openbis_calls
    @endpoint = FactoryBot.create(:openbis_endpoint)
    @endpoint.assay_types = ['TZ_FAIR_ASSAY'] # EXPERIMENTAL_STEP
    @util = Seek::Openbis::SeekUtil.new
    @creator = FactoryBot.create(:person, project: @endpoint.project)
    @study = FactoryBot.create :study, contributor: @creator
    @zample = Seek::Openbis::Zample.new(@endpoint, '20171002172111346-37')
    @experiment = Seek::Openbis::Experiment.new(@endpoint, '20171121152132641-51')
    User.current_user = @creator.user
  end

  test 'setup work' do
    assert @util
    assert @study
    assert @zample
    assert @creator
  end

  test 'openbis_debug is defined in config' do
    # puts Seek::Config.openbis_debug
    assert_not_nil Seek::Config.openbis_debug
  end

  test 'creates valid study with external_asset that can be saved' do
    investigation = FactoryBot.create(:investigation, contributor: @creator)
    assert investigation.save

    params = {investigation_id: investigation.id}
    sync_options = {link_datasets: '1', link_assays: '1'}

    experiment = Seek::Openbis::Experiment.new(@endpoint, '20171121152132641-51')

    asset = OpenbisExternalAsset.build(experiment, sync_options)

    study = @util.createObisStudy(params, @creator, asset)

    assert study.valid?

    assert_difference('Study.count') do
      assert_difference('ExternalAsset.count') do
        study.save!
      end
    end

    assert_equal "#{experiment.properties['NAME']} OpenBIS #{experiment.code}", study.title
    assert_equal @creator, study.contributor
    assert_same asset, study.external_asset
    assert_equal investigation, study.investigation
  end

  test 'creates valid assay with dependent external_asset that can be saved' do
    params = {study_id: @study.id}
    sync_options = {link_datasets: '1'}

    asset = OpenbisExternalAsset.build(@zample, sync_options)

    assay = @util.createObisAssay(params, @creator, asset)

    assert assay.valid?
    assert_equal assay.contributor, User.current_user.person
    assert assay.can_manage?
    assert assay.can_edit?

    assert_difference('Assay.count') do
      assert_difference('ExternalAsset.count') do
        assay.save!
      end
    end

    assert_equal "#{@zample.properties['NAME']} OpenBIS #{@zample.code}", assay.title
    assert_equal @creator, assay.contributor
    assert_same asset, assay.external_asset
  end

  test 'creates valid datafile with dependent external_assed that can be saved' do
    @endpoint.project.update(default_license: 'CC0-1.0')
    dataset = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')
    assert dataset

    asset = OpenbisExternalAsset.build(dataset)

    params = {}
    df = @util.createObisDataFile(params, @user, asset)

    assert df.valid?
    assert df.openbis?
    assert_equal 'CC0-1.0', df.license

    assert_difference('DataFile.count') do
      assert_difference('ExternalAsset.count') do
        df.save!
      end
    end

    # content blob is created as acording to logs there was SEEK code which assumes blobs presence in all assets
    # dont know seek enough to find all those places
    assert df.content_blob
    assert_equal "openbis2:#{@endpoint.id}/Seek::Openbis::Dataset/20160210130454955-23", df.content_blob.url
    assert df.content_blob.valid?
    assert df.content_blob.openbis?
    assert df.content_blob.custom_integration?
    assert df.content_blob.external_link?
    refute df.content_blob.show_as_external_link?

    # check if datafiles have been prefetched before saving df
    df = DataFile.find(df.id)
    df.reload

    dataset = df.external_asset.content
    assert dataset
    assert 3, dataset.json['dataset_files'].size
  end

  test 'extract title includes name from property if present' do
    dataset = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')
    refute dataset.properties['NAME']
    title = @util.extract_title(dataset)

    assert_equal 'OpenBIS 20160210130454955-23', title

    dataset.properties['NAME'] = 'TOM'
    title = @util.extract_title(dataset)
    assert_equal 'TOM OpenBIS 20160210130454955-23', title

    assert_equal 'Tomek First', @zample.properties['NAME']
    title = @util.extract_title(@zample)
    assert_equal 'Tomek First OpenBIS TZ3', title
  end

  test 'uri_for_content_blob follows expected pattern' do
    dataset = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')
    asset = OpenbisExternalAsset.build(dataset)

    expected = "openbis2:#{@endpoint.id}/Seek::Openbis::Dataset/20160210130454955-23"

    val = @util.uri_for_content_blob(asset)
    assert URI.parse(val)
    # puts val
    assert_equal expected, val

    asset = OpenbisExternalAsset.build(@zample)
    expected = "openbis2:#{@endpoint.id}/Seek::Openbis::Zample/#{@zample.perm_id}"
    val = @util.uri_for_content_blob(asset)
    # puts val
    assert_equal expected, val
  end

  test 'uri_for_content_blob differs from leggacy one' do
    dataset = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')
    asset = OpenbisExternalAsset.build(dataset)

    new_uri = @util.uri_for_content_blob(asset)
    old_uri = @util.legacy_uri_for_content_blob(dataset)
    # ds_uri = dataset.content_blob_uri

    assert_not_equal new_uri, old_uri
    # assert_not_equal new_uri, ds_uri

    assert_not_equal URI.parse(new_uri).scheme, URI.parse(old_uri).scheme
    # assert_not_equal URI.parse(new_uri).scheme, URI.parse(ds_uri).scheme
  end

  test 'legacy content blob uri is correct' do
    dataset = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')

    expected = "openbis:#{@endpoint.id}:dataset:20160210130454955-23"

    val = @util.legacy_uri_for_content_blob(dataset)
    assert_equal expected, val

    # puts dataset.content_blob_uri
    # assert_equal dataset.content_blob_uri, val
  end

  test 'should_follow_depended gives false on datafile or nil' do
    sync_options = {new_arrivals: '1'}
    dataset = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')
    asset = OpenbisExternalAsset.build(dataset, sync_options)

    refute @util.should_follow_dependent(asset)

    asset.seek_entity = FactoryBot.create :data_file
    assert asset.seek_entity

    refute @util.should_follow_dependent(asset)
  end

  test 'should_follow gives true if entity registered as assay or study and new_arrivals' do
    sync_options = {new_arrivals: '1'}
    asset = OpenbisExternalAsset.build(@zample, sync_options)

    refute @util.should_follow_dependent(asset)

    asset.seek_entity = FactoryBot.create :assay
    assert @util.should_follow_dependent(asset)

    asset = OpenbisExternalAsset.build(@experiment, sync_options)
    asset.seek_entity = FactoryBot.create :study
    assert @util.should_follow_dependent(asset)
  end

  test 'should_follow gives false if new_arrivals not set or config_disabled' do
    sync_options = {new_arrivals: '1', link_datasets: '1'}
    asset = OpenbisExternalAsset.build(@zample, sync_options)
    asset.seek_entity = FactoryBot.create :assay

    assert @util.should_follow_dependent(asset)

    Seek::Config.openbis_check_new_arrivals = false
    refute @util.should_follow_dependent(asset)

    Seek::Config.openbis_check_new_arrivals = true
    assert @util.should_follow_dependent(asset)

    sync_options = {new_arrivals: false, link_datasets: '1'}
    asset.sync_options = sync_options
    refute @util.should_follow_dependent(asset)
  end

  test 'fetch_current_entity_version fetches entity' do
    asset = OpenbisExternalAsset.build(@zample)

    entity = @util.fetch_current_entity_version(asset)
    assert entity
    assert_equal @zample, entity

    asset.external_id = 'XXX'
    assert_raises Exception do
      assert @util.fetch_current_entity_version(asset)
    end
  end

  test 'sync_asset_content refreshes dataset content and set sync status' do
    dataset1 = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')
    dataset2 = Seek::Openbis::Dataset.new(@endpoint, '20160215111736723-31')

    asset = OpenbisExternalAsset.build(dataset1)
    asset.synchronized_at = DateTime.now - 1.days
    asset.external_id = dataset2.perm_id
    asset.seek_entity = FactoryBot.create :data_file

    assert_not_equal dataset2.perm_id, asset.content.perm_id

    asset.sync_state = :refresh
    assert asset.save

    refute asset.synchronized?
    @util.sync_asset_content(asset)

    asset.reload

    assert asset.synchronized?
    assert_equal DateTime.now.to_date, asset.synchronized_at.to_date
    assert_equal dataset2.perm_id, asset.content.perm_id
  end

  test 'sync_asset_content refreshes zample content and set sync status' do
    asset = OpenbisExternalAsset.build(@zample)
    asset.synchronized_at = DateTime.now - 1.days
    asset.external_id = '20171002172639055-39'
    asset.seek_entity = FactoryBot.create :assay

    assert_not_equal '20171002172639055-39', asset.content.perm_id

    asset.sync_state = :refresh
    assert asset.save

    refute asset.synchronized?
    @util.sync_asset_content(asset)

    asset.reload

    assert asset.synchronized?
    assert_equal DateTime.now.to_date, asset.synchronized_at.to_date
    assert_equal '20171002172639055-39', asset.content.perm_id
  end

  test 'sync_asset_content increses failures and sets error message on failure' do
    dataset1 = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')

    asset = OpenbisExternalAsset.build(dataset1)
    asset.synchronized_at = DateTime.now - 1.days
    d = asset.synchronized_at
    asset.external_id = 'missing_id'
    asset.seek_entity = FactoryBot.create :data_file

    asset.sync_state = :refresh
    asset.failures = 1
    assert asset.save

    refute asset.failed?
    refute asset.err_msg
    @util.sync_asset_content(asset)

    asset = OpenbisExternalAsset.find(asset.id)
    asset.reload

    assert asset.failed?
    assert asset.err_msg
    assert_equal 2, asset.failures
    assert_equal d.to_date, asset.synchronized_at.to_date
  end

  test 'sync_asset_content queues index job if content changed' do
    dataset1 = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')
    dataset2 = Seek::Openbis::Dataset.new(@endpoint, '20160215111736723-31')

    data_file = FactoryBot.create :data_file
    asset = OpenbisExternalAsset.build(dataset1)
    asset.synchronized_at = DateTime.now - 1.days
    asset.external_id = dataset2.perm_id

    asset.seek_entity = data_file

    assert_not_equal dataset2.perm_id, asset.content.perm_id

    assert asset.save

    ReindexingQueue.destroy_all
    assert_enqueued_jobs(1, only: ReindexingJob) do
      @util.sync_asset_content(asset)
    end
    assert ReindexingQueue.exists?(item: data_file)

    asset.reload
    ReindexingQueue.destroy_all
    assert_no_enqueued_jobs(only: ReindexingJob) do
      # same content no change
      @util.sync_asset_content(asset)
    end
    refute ReindexingQueue.exists?(item: data_file)
  end

  test 'sync_external_asset refreshes dataset content and set sync status' do
    dataset1 = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')
    dataset2 = Seek::Openbis::Dataset.new(@endpoint, '20160215111736723-31')

    asset = OpenbisExternalAsset.build(dataset1)
    asset.synchronized_at = DateTime.now - 1.days
    asset.external_id = dataset2.perm_id
    asset.seek_entity = FactoryBot.create :data_file

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

  test 'sync_external_asset queues data_file index job if content changed' do
    dataset1 = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')
    dataset2 = Seek::Openbis::Dataset.new(@endpoint, '20160215111736723-31')

    data_file = FactoryBot.create :data_file
    asset = OpenbisExternalAsset.build(dataset1)
    asset.synchronized_at = DateTime.now - 1.days
    asset.external_id = dataset2.perm_id

    asset.seek_entity = data_file

    assert_not_equal dataset2.perm_id, asset.content.perm_id

    assert asset.save

    ReindexingQueue.destroy_all
    assert_enqueued_jobs(1, only: ReindexingJob) do
      @util.sync_external_asset(asset)
    end
    assert ReindexingQueue.exists?(item: data_file)

    asset.reload
    ReindexingQueue.destroy_all
    assert_no_enqueued_jobs(only: ReindexingJob) do
      # same content no change
      @util.sync_external_asset(asset)
    end
    refute ReindexingQueue.exists?(item: data_file)
  end

  test 'sync_external_asset links datasets to assay if follow links' do
    refute @zample.dataset_ids.empty?

    assay = FactoryBot.create :assay, contributor: @creator

    assert assay.data_files.empty?

    asset = OpenbisExternalAsset.build(@zample)
    asset.sync_options = {link_datasets: '1', new_arrivals: '1'}
    asset.sync_state = :refresh
    asset.seek_entity = assay
    # need to save to have the assay to asset link updated
    assert asset.save

    @util.sync_external_asset(asset)

    assert asset.synchronized?
    refute assay.data_files.empty?
    assert_equal @zample.dataset_ids.length, assay.data_files.length
  end

  test 'sync_external_asset does not link datasets to assay if sync_options not set' do
    refute @zample.dataset_ids.empty?

    assay = FactoryBot.create :assay

    assert assay.data_files.empty?

    asset = OpenbisExternalAsset.build(@zample)
    asset.sync_options = {link_datasets: '0'}
    asset.sync_state = :refresh
    asset.seek_entity = assay
    # need to save to have the assay to asset link updated
    assert asset.save

    @util.sync_external_asset(asset)

    assert asset.synchronized?
    assert assay.data_files.empty?
  end

  test 'sync_external_asset does not link to study if sync_options not set' do
    refute @experiment.dataset_ids.empty?
    refute @experiment.sample_ids.empty?

    study = FactoryBot.create :study

    assert study.assays.empty?
    assert study.related_data_files.empty?

    asset = OpenbisExternalAsset.build(@experiment)
    asset.sync_options = {link_datasets: '0'}
    asset.seek_entity = study
    # need to save to have the assay to asset link updated
    assert asset.save

    @util.sync_external_asset(asset)

    study.reload
    assert asset.synchronized?
    assert study.assays.empty?
    assert study.related_data_files.empty?
  end

  test 'sync_external_asset links to study if sync_options set' do
    refute @experiment.dataset_ids.empty?
    refute @experiment.sample_ids.empty?

    study = FactoryBot.create :study, contributor: @creator

    assert study.assays.empty?
    assert study.related_data_files.empty?

    asset = OpenbisExternalAsset.build(@experiment)
    asset.sync_options = {link_datasets: '1', new_arrivals: '1'}
    asset.seek_entity = study
    # need to save to have the assay to asset link updated
    assert asset.save

    @util.sync_external_asset(asset)

    study.reload
    assert asset.synchronized?
    assert_equal 1, study.assays.size # the fake files assay
    assert_equal @experiment.dataset_ids.size, study.related_data_files.size

    asset.sync_options = {link_datasets: '1', linked_assays: @experiment.sample_ids, new_arrivals: '1'}
    @util.sync_external_asset(asset)

    study.reload
    assert_equal @experiment.sample_ids.size + 1, study.assays.size # one extra for linking datasets
    assert_equal @experiment.dataset_ids.size, study.related_data_files.size
  end

  test 'sync_external_asset creates study dependent objects as the current_user' do
    refute @experiment.dataset_ids.empty?
    refute @experiment.sample_ids.empty?

    policy = FactoryBot.create(:public_policy)
    policy.permissions.build(contributor: @endpoint.project, access_type: Policy::EDITING)

    study = FactoryBot.create :study, contributor: @creator, policy: policy

    user = FactoryBot.create(:person, project: @endpoint.project)
    assert_not_equal user, @creator

    assert study.assays.empty?
    assert study.related_data_files.empty?

    asset = OpenbisExternalAsset.build(@experiment)
    asset.sync_options = {link_datasets: '1', linked_assays: @experiment.sample_ids, new_arrivals: '1'}
    asset.seek_entity = study
    # need to save to have the assay to asset link updated
    assert asset.save

    reg = nil
    User.with_current_user(user.user) do
      reg = @util.sync_external_asset(asset)
    end

    assert_equal [], reg

    study.reload
    assert_equal @experiment.sample_ids.size + 1, study.assays.size # one extra for linking datasets
    assert_equal @experiment.dataset_ids.size, study.related_data_files.size

    assert_equal user, study.assays.first.contributor
    assert_equal user, study.related_data_files.first.contributor

  end

  test 'sync_external_asset gives sensible errors if there is permission issue' do
    refute @experiment.dataset_ids.empty?
    refute @experiment.sample_ids.empty?

    # policy = FactoryBot.create(:public_policy)
    # policy.permissions.build(contributor: @endpoint.project, access_type: Policy::EDITING)
    # study = FactoryBot.create :study, contributor: @creator, policy: policy

    study = FactoryBot.create :study, contributor: @creator

    user = FactoryBot.create(:person, project: @endpoint.project)
    assert_not_equal user, @creator

    asset = OpenbisExternalAsset.build(@experiment)
    asset.sync_options = {link_datasets: '1', linked_assays: @experiment.sample_ids, new_arrivals: '1'}
    asset.seek_entity = study
    # need to save to have the assay to asset link updated
    assert asset.save

    reg = nil
    User.with_current_user(user.user) do
      reg = @util.sync_external_asset(asset)
    end

    assert reg.length > 0

    study.reload
    assert_equal 0, study.assays.size # one extra for linking datasets
    assert_equal 0, study.related_data_files.size


  end


  test 'sync_external_asset does not to study if new_arrivals not set' do
    refute @experiment.dataset_ids.empty?
    refute @experiment.sample_ids.empty?

    study = FactoryBot.create :study

    assert study.assays.empty?
    assert study.related_data_files.empty?

    asset = OpenbisExternalAsset.build(@experiment)
    asset.sync_options = {link_datasets: '1', link_assays: '1'}
    asset.seek_entity = study
    # need to save to have the assay to asset link updated
    assert asset.save

    @util.sync_external_asset(asset)

    study.reload
    assert asset.synchronized?
    assert_equal 0, study.assays.size # even no fake files assay
    assert_equal 0, study.related_data_files.size

    refute @experiment.sample_ids.empty?
    asset.sync_options = {link_datasets: '1', linked_assays: @experiment.sample_ids}
    @util.sync_external_asset(asset)

    study.reload
    assert_equal 0, study.assays.size # even no fake files assay
    assert_equal 0, study.related_data_files.size
  end

  test 'follow_dependent links datasets to assay' do
    refute @zample.dataset_ids.empty?

    assay = FactoryBot.create :assay, contributor: @creator

    assert assay.data_files.empty?

    asset = OpenbisExternalAsset.build(@zample)
    asset.sync_options = {link_datasets: '1'}
    asset.seek_entity = assay
    asset.save!

    reg_info = @util.follow_dependent_from_asset(asset)
    assert_equal [], reg_info.issues

    refute assay.data_files.empty?
    assert_equal @zample.dataset_ids.length, assay.data_files.length
    assert_equal @zample.dataset_ids.length, reg_info.created.length
  end

  ## --------- linking datasets to assay ---------- ##

  test 'associate_data_sets links datasets with assay creating new datafiles if necessary' do
    assay = FactoryBot.create :assay, contributor: @creator

    df0 = FactoryBot.create :data_file, contributor: @creator
    assay.associate(df0)
    assert df0.persisted?
    assert_equal 1, assay.data_files.length

    datasets = Seek::Openbis::Dataset.new(@endpoint).find_by_perm_ids(['20171002172401546-38', '20171002190934144-40', '20171004182824553-41'])
    assert_equal 3, datasets.length

    df1 = @util.createObisDataFile({}, @creator, OpenbisExternalAsset.build(datasets[0]))
    assert df1.save

    reg_info = nil
    assert_difference('AssayAsset.count', 3) do
      assert_difference('DataFile.count', 2) do
        assert_difference('ExternalAsset.count', 2) do
          reg_info = @util.associate_data_sets(assay, datasets)
        end
      end
    end

    assert_equal [], reg_info.issues
    assert_equal 2, reg_info.created.count
    reg_info.created.each {|d| assert d.is_a?(DataFile)}

    assay.reload
    assert_equal 4, assay.data_files.length
  end

  test 'associate_data_sets_ids links datasets with assay creating new datafiles if necessary' do
    assay = FactoryBot.create :assay, contributor: @creator

    df0 = FactoryBot.create :data_file, contributor: @creator
    assay.associate(df0)
    assert df0.persisted?
    assert_equal 1, assay.data_files.length

    data_sets_ids = ['20171002172401546-38', '20171002190934144-40', '20171004182824553-41']

    reg_info = nil
    assert_difference('AssayAsset.count', 3) do
      assert_difference('DataFile.count', 3) do
        assert_difference('ExternalAsset.count', 3) do
          reg_info = @util.associate_data_sets_ids(assay, data_sets_ids, @endpoint)
        end
      end
    end

    assert_equal [], reg_info.issues
    assert_equal 3, reg_info.created.count

    assay.reload
    assert_equal 4, assay.data_files.length
  end

  ## --------- linking datasets to assay end ---------- ##

  ## --------- linking assays to study ---------- ##
  test 'associate_zamples_as_assays links zamples as new assays with study' do
    study = FactoryBot.create :study, contributor: @creator

    assert study.assays.empty?

    zamples = Seek::Openbis::Zample.new(@endpoint).find_by_perm_ids(['20171002172111346-37', '20171002172639055-39'])
    assert_equal 2, zamples.length

    reg_info = nil
    sync_options = {}

    assert_difference('Assay.count', 2) do
      assert_difference('AssayAsset.count', 0) do
        assert_difference('DataFile.count', 0) do
          assert_difference('ExternalAsset.count', 2) do
            reg_info = @util.associate_zamples_as_assays(study, zamples, sync_options)
          end
        end
      end
    end

    study.reload
    assert_equal 2, study.assays.count
    assert_equal 2, reg_info.created.count
    assert_equal [], reg_info.issues
  end

  test 'associate_zamples_as_assays links datafiles to assays under the study if selected so' do
    study = FactoryBot.create :study, contributor: @creator

    assert study.assays.empty?

    zamples = Seek::Openbis::Zample.new(@endpoint).find_by_perm_ids(['20171002172111346-37', '20171002172639055-39'])
    assert_equal 2, zamples.length

    ds_count = zamples.map(&:dataset_ids)
                   .flatten.length

    assert ds_count > 0

    sync_options = {link_datasets: '1'}
    reg_info = nil

    assert_difference('Assay.count', 2) do
      assert_difference('AssayAsset.count', ds_count) do
        assert_difference('DataFile.count', ds_count) do
          assert_difference('ExternalAsset.count', 2 + ds_count) do
            reg_info = @util.associate_zamples_as_assays(study, zamples, sync_options)
          end
        end
      end
    end

    study.reload
    assert_equal 2, study.assays.count
    assert_equal ds_count, study.related_data_files.count

    assert_equal 2 + ds_count, reg_info.created.count
    assert_equal [], reg_info.issues
  end

  test 'associate_zamples_as_assays reports issues if zample already registered but not as assay' do
    study = FactoryBot.create :study, contributor: @creator

    assert study.assays.empty?

    zamples = Seek::Openbis::Zample.new(@endpoint).find_by_perm_ids(['20171002172111346-37', '20171002172639055-39'])
    assert_equal 2, zamples.length

    df = FactoryBot.create :data_file, contributor: @creator
    ea = OpenbisExternalAsset.find_or_create_by_entity(zamples[0])
    df.external_asset = ea

    assert df.can_edit?
    assert ea.can_edit?
    assert df.save
    assert ea.save

    sync_options = {}
    reg_info = nil
    assert_difference('Assay.count', 1) do
      assert_difference('AssayAsset.count', 0) do
        assert_difference('DataFile.count', 0) do
          assert_difference('ExternalAsset.count', 1) do
            reg_info = @util.associate_zamples_as_assays(study, zamples, sync_options)
          end
        end
      end
    end

    refute reg_info.issues.empty?
    assert_equal 1, reg_info.created.count

    study.reload
    assert_equal 1, study.assays.count
  end

  test 'associate_zamples_as_assays reports issues if zample already registered under different study' do
    study = FactoryBot.create :study, contributor: @creator

    assert study.assays.empty?

    zamples = Seek::Openbis::Zample.new(@endpoint).find_by_perm_ids(['20171002172111346-37', '20171002172639055-39'])
    assert_equal 2, zamples.length

    study2 = FactoryBot.create :study, contributor: @creator
    assay2 = FactoryBot.create :assay, contributor: @creator
    assay2.study = study2

    ea = OpenbisExternalAsset.find_or_create_by_entity(zamples[0])
    assay2.external_asset = ea
    assert_equal study2, assay2.study

    assay2.valid?
    # puts assay2.errors.full_messages

    disable_authorization_checks do
      assert assay2.save
      assert ea.save
    end

    sync_options = {}
    reg_info = nil
    assert_difference('Assay.count', 1) do
      assert_difference('AssayAsset.count', 0) do
        assert_difference('DataFile.count', 0) do
          assert_difference('ExternalAsset.count', 1) do
            reg_info = @util.associate_zamples_as_assays(study, zamples, sync_options)
          end
        end
      end
    end

    refute reg_info.issues.empty?
    assert_equal 1, reg_info.created.count

    study.reload
    assert_equal 1, study.assays.count

    study2.reload
    assay2.reload
    assert_equal study2, assay2.study
  end

  test 'associate_zamples_as_assays sets sync_options for new assays and leaves existing untouched' do
    study = FactoryBot.create :study, contributor: @creator

    assert study.assays.empty?

    zamples = Seek::Openbis::Zample.new(@endpoint).find_by_perm_ids(['20171002172111346-37', '20171002172639055-39'])
    assert_equal 2, zamples.length

    assay2 = FactoryBot.create :assay, contributor: @creator
    assay2.study = study

    ea = OpenbisExternalAsset.find_or_create_by_entity(zamples[0])
    org_sync_options = {tomek: 'yes'}
    ea.sync_options = org_sync_options
    assay2.external_asset = ea

    disable_authorization_checks do
      assert assay2.save
      assert ea.save
    end

    sync_options = {edin: 1}
    reg_info = nil
    assert_difference('Assay.count', 1) do
      reg_info = @util.associate_zamples_as_assays(study, zamples, sync_options)
    end

    assert reg_info.issues.empty?
    study.reload

    assay2 = study.assays.first
    assert_equal org_sync_options, assay2.external_asset.sync_options

    assay_new = study.assays.last
    assert_equal sync_options, assay_new.external_asset.sync_options
  end

  ## --------- linking assays to study end ---------- ##

  ## --------- follow_study_dependent_assays ---------- ##

  test 'follow_study_dependent_assays registers assays if set so' do
    study = FactoryBot.create :study, contributor: @creator
    assert study.assays.empty?
    refute @experiment.sample_ids.empty?

    # no linking
    sync_options = {}
    reg_info = @util.follow_study_dependent_assays(@experiment, study, sync_options)

    assert_equal [], reg_info.issues
    assert_equal [], reg_info.created

    study.reload
    assert study.assays.empty?

    # automated assays linking
    assert(@experiment.sample_ids.length > 1)
    sync_options = {link_assays: '1'}
    reg_info = @util.follow_study_dependent_assays(@experiment, study, sync_options)

    assert_equal [], reg_info.issues
    assert_equal @experiment.sample_ids.length, reg_info.created.length

    study.reload
    assert_equal @experiment.sample_ids.length, study.assays.count
  end

  test 'follow_study_dependent_assays registers selected assays if set so' do
    study = FactoryBot.create :study, contributor: @creator
    assert study.assays.empty?
    assert(@experiment.sample_ids.length > 1)

    # selected assays
    sync_options = {linked_assays: [@experiment.sample_ids[0]]}
    reg_info = @util.follow_study_dependent_assays(@experiment, study, sync_options)

    assert_equal [], reg_info.issues
    assert_equal 1, reg_info.created.length

    study.reload
    assert_equal 1, study.assays.count
  end

  test 'follow_study_dependent_assays registers assays with unique titles' do
    study = FactoryBot.create :study, contributor: @creator
    assert study.assays.empty?
    assert @experiment.sample_ids.size > 1

    # automated assays linking
    sync_options = {link_assays: '1'}
    reg_info = @util.follow_study_dependent_assays(@experiment, study, sync_options)

    assert_equal [], reg_info.issues

    study.reload
    assert_equal @experiment.sample_ids.length, study.assays.count
    titles = study.assays.map(&:title).uniq
    assert_equal @experiment.sample_ids.length, titles.length
  end

  ## --------- follow_study_dependent_assays end ---------- ##

  ## --------- follow_study_dependent_datafiles ---------- ##

  test 'follow_study_dependent_datafiles registers datafiles under fake assay if said so' do
    study = FactoryBot.create :study, contributor: @creator
    assert study.assays.empty?
    assert study.related_data_files.empty?
    refute @experiment.dataset_ids.empty?

    sync_options = {}

    reg_info = @util.follow_study_dependent_datafiles(@experiment, study, sync_options)

    assert_equal [], reg_info.issues
    assert_equal [], reg_info.created

    study.reload
    assert study.assays.empty?
    assert study.related_data_files.empty?

    sync_options = {link_datasets: '1'}
    reg_info = @util.follow_study_dependent_datafiles(@experiment, study, sync_options)

    assert_equal [], reg_info.issues
    assert_equal @experiment.dataset_ids.length + 1, reg_info.created.count

    study.reload
    assert_equal @experiment.dataset_ids.length, study.related_data_files.count
    assert_equal 'OpenBIS FILES', study.assays.first!.title
    assert_equal @experiment.dataset_ids.length, study.assays.first!.data_files.count
    assert reg_info.created.include? study.assays.first!
  end

  test 'follow_study_dependent_datafiles registers selected datafiles under fake assay if said so' do
    study = FactoryBot.create :study, contributor: @creator
    assert study.assays.empty?
    assert study.related_data_files.empty?
    refute @experiment.dataset_ids.empty?

    sync_options = {linked_datasets: [@experiment.dataset_ids[1]]}
    reg_info = @util.follow_study_dependent_datafiles(@experiment, study, sync_options)

    assert_equal [], reg_info.issues
    assert_equal 1 + 1, reg_info.created.count

    study.reload
    assert_equal 1, study.related_data_files.count
    assert_equal 'OpenBIS FILES', study.assays.first!.title
  end

  test 'follow_study_dependent_datafiles registers datafiles with unique names' do
    study = FactoryBot.create :study, contributor: @creator
    assert study.assays.empty?
    assert study.related_data_files.empty?
    assert @experiment.dataset_ids.size > 1

    sync_options = {link_datasets: '1'}
    reg_info = @util.follow_study_dependent_datafiles(@experiment, study, sync_options)

    assert_equal [], reg_info.issues

    study.reload
    assert_equal @experiment.dataset_ids.length, study.related_data_files.count

    titles = study.related_data_files.map(&:title).uniq
    assert_equal @experiment.dataset_ids.length, titles.length
  end

  ## --------- follow_study_dependent_datafiles end ---------- ##

  ## --------- follow_assay ---------- ##

  test 'follow assay registers all dependent datasets if set so' do
    # puts @zample.dataset_ids

    assay = FactoryBot.create :assay, contributor: @creator
    es = OpenbisExternalAsset.find_or_create_by_entity(@zample)
    es.sync_options = {link_datasets: '1'}
    assay.external_asset = es

    assert assay.save
    assert assay.data_files.empty?
    refute @zample.dataset_ids.empty?

    reg_info = @util.follow_assay_dependent(assay)
    assert reg_info.issues.empty?

    assert_equal @zample.dataset_ids.count, reg_info.created.count
    assert_equal @zample.dataset_ids.count, assay.data_files.count
  end

  test 'follow assay registers selected detasets' do
    # puts @zample.dataset_ids

    assay = FactoryBot.create :assay, contributor: @creator
    es = OpenbisExternalAsset.find_or_create_by_entity(@zample)
    es.sync_options = {linked_datasets: [@zample.dataset_ids[1]]}
    assay.external_asset = es

    assert assay.save
    assert assay.data_files.empty?

    reg_info = @util.follow_assay_dependent(assay)
    assert reg_info.issues.empty?
    assert_equal 1, reg_info.created.count

    assert_equal 1, assay.data_files.count
  end

  test 'follow assay registers dependent datasets with unique names' do
    assay = FactoryBot.create :assay, contributor: @creator
    es = OpenbisExternalAsset.find_or_create_by_entity(@zample)
    es.sync_options = {link_datasets: '1'}
    assay.external_asset = es

    assert assay.save
    assert assay.data_files.empty?
    assert @zample.dataset_ids.size > 1

    reg_info = @util.follow_assay_dependent(assay)
    assert reg_info.issues.empty?

    assert_equal @zample.dataset_ids.size, assay.data_files.size
    titles = assay.data_files.map(&:title).uniq
    assert_equal @zample.dataset_ids.size, titles.size
  end

  ## --------- follow_assay end ---------- ##

  test 'extract_requested_sets gives all sets from zample if linked is selected' do
    assert_equal 3, @zample.dataset_ids.length
    sync_options = {}
    params = {}

    assert_equal [], @util.extract_requested_sets(@zample, sync_options)

    sync_options = {link_datasets: '1'}
    assert_same @zample.dataset_ids, @util.extract_requested_sets(@zample, sync_options)

    sync_options = {link_datasets: '1', linked_datasets: ['123']}
    assert_same @zample.dataset_ids, @util.extract_requested_sets(@zample, sync_options)
  end

  test 'extract_requested_sets gives only selected sets that belongs to zample' do
    sync_options = {}

    assert_equal 3, @zample.dataset_ids.length

    assert_equal [], @util.extract_requested_sets(@zample, sync_options)

    sync_options = {linked_datasets: []}
    assert_equal [], @util.extract_requested_sets(@zample, sync_options)

    sync_options = {linked_datasets: ['123']}
    assert_equal [], @util.extract_requested_sets(@zample, sync_options)

    sync_options = {linked_datasets: ['123', @zample.dataset_ids[0]]}
    assert_equal [@zample.dataset_ids[0]], @util.extract_requested_sets(@zample, sync_options)

    sync_options = {linked_datasets: @zample.dataset_ids}
    assert_equal @zample.dataset_ids, @util.extract_requested_sets(@zample, sync_options)
  end

  test 'filter_assay_like_zamples returns ids of only samples marked as assays in openbis types' do
    ids = ['20171002172111346-37', '20171002172639055-39', '20171121152441898-53']
    zamples = Seek::Openbis::Zample.new(@endpoint).find_by_perm_ids(ids)

    @endpoint.assay_types = ['TZ_FAIR_ASSAY']
    # , EXPERIMENTAL_STEP
    corr = @util.filter_assay_like_zamples(zamples, @endpoint)
    assert_equal 2, corr.length
    assert_equal ['20171002172111346-37', '20171002172639055-39'], corr.map(&:perm_id)

    @endpoint.assay_types = 'TZ_FAIR_ASSAY EXPERIMENTAL_STEP'
    corr = @util.filter_assay_like_zamples(zamples, @endpoint)
    assert_equal 3, corr.length
    assert_equal ['20171121152441898-53', '20171002172111346-37', '20171002172639055-39'], corr.map(&:perm_id)
  end

  test 'extract_requested_assays gives all assay-like zamples if linked is selected' do
    assert_equal 2, @experiment.sample_ids.length
    sync_options = {}

    assert_equal [], @util.extract_requested_assays(@experiment, sync_options)

    sync_options = {link_assays: '1'}
    assert_equal @experiment.sample_ids, @util.extract_requested_assays(@experiment, sync_options).map(&:perm_id)

    sync_options = {link_assays: '1', linked_zamples: ['123']}
    assert_equal @experiment.sample_ids, @util.extract_requested_assays(@experiment, sync_options).map(&:perm_id)
  end

  test 'extract_requested_assays gives explicit selected non-assay-like zamples even if link selected' do
    @experiment.openbis_endpoint.assay_types = []

    assert_equal 2, @experiment.sample_ids.length
    sync_options = {link_assays: '1'}

    assert_equal [], @util.extract_requested_assays(@experiment, sync_options)

    sync_options = {link_assays: '1', linked_assays: ['123', @experiment.sample_ids[0]]}
    assert_equal [@experiment.sample_ids[0]], @util.extract_requested_assays(@experiment, sync_options).map(&:perm_id)

    # can have multiple
    sync_options = {link_assays: '1', linked_assays: [@experiment.sample_ids[0], @experiment.sample_ids[1]]}
    assert_equal [@experiment.sample_ids[0], @experiment.sample_ids[1]], @util.extract_requested_assays(@experiment, sync_options).map(&:perm_id)

    # no duplicates
    @experiment.openbis_endpoint.assay_types = 'TZ_FAIR_ASSAY'
    sync_options = {link_assays: '1', linked_assays: ['123', @experiment.sample_ids[0]]}
    assert_equal @experiment.sample_ids, @util.extract_requested_assays(@experiment, sync_options).map(&:perm_id)
  end

  test 'extract_requested_assays gives only selected zamples that belongs to exp' do
    sync_options = {}

    assert_equal 2, @experiment.sample_ids.length

    assert_equal [], @util.extract_requested_assays(@experiment, sync_options)

    sync_options = {linked_assays: []}
    assert_equal [], @util.extract_requested_assays(@experiment, sync_options).map(&:perm_id)

    sync_options = {linked_assays: ['123']}
    assert_equal [], @util.extract_requested_assays(@experiment, sync_options).map(&:perm_id)

    sync_options = {linked_assays: ['123', @experiment.sample_ids[0]]}
    assert_equal [@experiment.sample_ids[0]], @util.extract_requested_assays(@experiment, sync_options).map(&:perm_id)

    sync_options = {linked_assays: @experiment.sample_ids}
    assert_equal @experiment.sample_ids, @util.extract_requested_assays(@experiment, sync_options).map(&:perm_id)
  end

  test 'fake_file_assay gives first assay of the openbis name' do
    disable_authorization_checks do
      study = FactoryBot.create :study, contributor: @creator
      assay1 = FactoryBot.create :assay, contributor: @creator
      assay1.title = 'Cos'
      assay1.study = study
      assert assay1.save

      assay2 = FactoryBot.create :assay, contributor: @creator
      assay2.title = 'OpenBIS FILES'
      assay2.study = study
      assert assay2.save

      assert_equal assay2, @util.fake_file_assay(study)
    end
  end

  test 'fake_file_assay creates assay of the openbis name if missing' do
    study = FactoryBot.create :study, contributor: @creator
    assert study.assays.empty?
    assay = @util.fake_file_assay(study)

    assert_equal 'OpenBIS FILES', assay.title
    assert_equal study, assay.study
    assert assay.persisted?
    assert_not_empty assay.description
  end

  test 'fetch_current_entity_version gets fresh version ignoring cache' do
    dataset1 = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')

    dj = dataset1.json
    dj['code'] = '123'
    val = {'datasets' => [dj]}

    assert_not_equal '123', dataset1.code

    explicit_query_mock
    set_mocked_value_for_id('20160210130454955-23', val)

    dataset1 = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')
    assert_not_equal '123', dataset1.code

    asset = OpenbisExternalAsset.build(dataset1)
    dataset2 = @util.fetch_current_entity_version(asset)
    assert_equal '123', dataset2.code
  end

  test 'assay_types gives types annotated as assay if semantic is used' do
    @endpoint.assay_types = []
    types = @util.assay_types(@endpoint, true)
    assert types
    codes = types.map(&:code)
    assert_equal %w[TZ_FAIR_ASSAY UNKNOWN], codes
  end

  test 'assay_types gives types configured as assays in the endpoint' do
    @endpoint.assay_types = 'EXPERIMENTAL_STEP'
    refute @endpoint.assay_types.empty?
    types = @util.assay_types(@endpoint, false)
    assert types
    codes = types.map(&:code)
    assert_equal ['EXPERIMENTAL_STEP'], codes

    @endpoint.assay_types = []
    types = @util.assay_types(@endpoint)
    assert types
    assert types.empty?
  end

  test 'assay_types merges annotated and configured in endpoint' do
    @endpoint.assay_types = 'EXPERIMENTAL_STEP'
    refute @endpoint.assay_types.empty?
    types = @util.assay_types(@endpoint, true)
    assert types
    codes = types.map(&:code)
    assert_equal %w[TZ_FAIR_ASSAY UNKNOWN EXPERIMENTAL_STEP], codes
  end

  test 'study_types gives experiments types configured in endpoint' do
    refute @endpoint.study_types.empty?
    types = @util.study_types(@endpoint)
    assert types
    codes = types.map(&:code)
    assert_equal ['DEFAULT_EXPERIMENT'], codes

    @endpoint.study_types = []
    types = @util.study_types(@endpoint)
    assert types.empty?
  end

  test 'dataset_types gives all dataset types' do
    types = @util.dataset_types(@endpoint)
    assert types
    codes = types.map(&:code)
    assert_equal 7, codes.size
    assert_includes codes, 'TZ_FAIR'
  end

  test 'validate_expected_seek_type issues warnings if mismatch' do
    df1 = FactoryBot.create :data_file
    df2 = FactoryBot.create :data_file
    assay = FactoryBot.create :assay

    a1 = OpenbisExternalAsset.new
    a1.seek_entity = df1

    a2 = OpenbisExternalAsset.new
    a2.seek_entity = df2

    a3 = OpenbisExternalAsset.new
    a3.seek_entity = assay

    a4 = OpenbisExternalAsset.new

    collection = []
    type = DataFile

    assert_equal [], @util.validate_expected_seek_type(collection, type)

    collection = [a4]
    assert_equal [], @util.validate_expected_seek_type(collection, type)

    collection = [a1, a4, a2]
    assert_equal [], @util.validate_expected_seek_type(collection, type)

    collection = [a3]
    assert_equal 1, @util.validate_expected_seek_type(collection, type).count
    assert_equal ["#{a3.id} already registered as Assay #{assay.id}"],
                 @util.validate_expected_seek_type(collection, type)

    type = Assay
    assert_equal 0, @util.validate_expected_seek_type(collection, type).count

    collection = [a1, a2, a3, a4]
    type = Assay
    assert_equal 2, @util.validate_expected_seek_type(collection, type).count
  end

  test 'validate_study_relationship issues warnings if mismatch' do
    study1 = FactoryBot.create :study
    study2 = FactoryBot.create :study

    as1 = FactoryBot.create(:assay)
    as1.study = study1
    a1 = OpenbisExternalAsset.new(external_service: 1, external_id: 1)
    a1.seek_entity = as1
    as1.external_asset = a1

    as2 = FactoryBot.create(:assay)
    as2.study = study1
    a2 = OpenbisExternalAsset.new(external_service: 1, external_id: 2)
    a2.seek_entity = as2
    as2.external_asset = a2

    as3 = FactoryBot.create(:assay)
    as3.study = study2
    a3 = OpenbisExternalAsset.new(external_service: 1, external_id: 3)
    a3.seek_entity = as3
    as3.external_asset = a3

    collection = []
    assert_equal [], @util.validate_study_relationship(collection, study1)

    collection = [as1, as2]
    assert_equal [], @util.validate_study_relationship(collection, study1)

    collection = [as3]
    assert_equal 1, @util.validate_study_relationship(collection, study1).count
    assert_equal ["#{a3.external_id} already registered under different Study #{study2.id}"],
                 @util.validate_study_relationship(collection, study1)

    collection = [as1, as3, as2]
    assert_equal 2, @util.validate_study_relationship(collection, study2).count
  end
end
