require 'test_helper'
require 'openbis_test_helper'

class SeekUtilTest < ActiveSupport::TestCase
  #fixtures :studies

  def setup
    mock_openbis_calls
    @endpoint = Factory(:openbis_endpoint)
    @endpoint.assay_types = ['TZ_FAIR_ASSAY'] # EXPERIMENTAL_STEP
    @util = Seek::Openbis::SeekUtil.new
    @study = Factory :study #studies(:junk_study)
    @zample = Seek::Openbis::Zample.new(@endpoint, '20171002172111346-37')
    @experiment = Seek::Openbis::Experiment.new(@endpoint, '20171121152132641-51')
    @creator = Factory(:person)
  end

  test 'setup work' do
    assert @util
    assert @study
    assert @zample
    assert @creator
  end

  test 'creates valid study with external_asset that can be saved' do

    investigation = Factory(:investigation)
    assert investigation.save

    params = { investigation_id: investigation.id }
    sync_options = { link_datasets: '1', link_assays: '1' }

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

    params = { study_id: @study.id }
    sync_options = { link_datasets: '1' }

    asset = OpenbisExternalAsset.build(@zample, sync_options)

    assay = @util.createObisAssay(params, @creator, asset)

    assert assay.valid?

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
    dataset = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')
    assert dataset

    asset = OpenbisExternalAsset.build(dataset)

    params = {}
    df = @util.createObisDataFile(params, @user, asset)

    assert df.valid?

    assert_difference('DataFile.count') do
      assert_difference('ExternalAsset.count') do
        df.save!
      end
    end

    assert df.content_blob
  end

  test 'extract title includes name from property if present' do
    dataset = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')
    refute dataset.properties['NAME']
    title = @util.extract_title(dataset)

    assert_equal "OpenBIS 20160210130454955-23", title

    dataset.properties['NAME'] = "TOM"
    title = @util.extract_title(dataset)
    assert_equal "TOM OpenBIS 20160210130454955-23", title

    assert_equal 'Tomek First', @zample.properties['NAME']
    title = @util.extract_title(@zample)
    assert_equal "Tomek First OpenBIS TZ3", title

  end

  test 'uri_for_content_blob follows expected pattern' do
    dataset = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')
    asset = OpenbisExternalAsset.build(dataset)

    expected = "openbis2:#{@endpoint.id}/Seek::Openbis::Dataset/20160210130454955-23"

    val = @util.uri_for_content_blob(asset)
    assert URI.parse(val)
    puts val
    assert_equal expected, val

    asset = OpenbisExternalAsset.build(@zample)
    expected = "openbis2:#{@endpoint.id}/Seek::Openbis::Zample/#{@zample.perm_id}"
    val = @util.uri_for_content_blob(asset)
    puts val
    assert_equal expected, val

  end

  test 'uri_for_content_blob differs from leggacy one' do
    dataset = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')
    asset = OpenbisExternalAsset.build(dataset)

    new_uri = @util.uri_for_content_blob(asset)
    old_uri = @util.legacy_uri_for_content_blob(dataset)
    ds_uri = dataset.content_blob_uri

    assert_not_equal new_uri, old_uri
    assert_not_equal new_uri, ds_uri

    assert_not_equal URI.parse(new_uri).scheme, URI.parse(old_uri).scheme
    assert_not_equal URI.parse(new_uri).scheme, URI.parse(ds_uri).scheme

  end

  test 'legacy content blob uri is correct' do
    dataset = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')

    expected = "openbis:#{@endpoint.id}:dataset:20160210130454955-23"

    val = @util.legacy_uri_for_content_blob(dataset)
    assert_equal expected, val

    #puts dataset.content_blob_uri
    assert_equal dataset.content_blob_uri, val

  end

  test 'should_follow_depended gives false on datafile or nil' do

    dataset = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')
    asset = OpenbisExternalAsset.build(dataset)

    refute @util.should_follow_dependent(asset)

    asset.seek_entity = Factory :data_file
    assert asset.seek_entity

    refute @util.should_follow_dependent(asset)

  end

  test 'should_follow gives true if part of assay or study' do

    sync_options = {}
    asset = OpenbisExternalAsset.build(@zample, sync_options)

    refute @util.should_follow_dependent(asset)

    asset.seek_entity = Factory :assay
    assert @util.should_follow_dependent(asset)

    asset = OpenbisExternalAsset.build(@experiment, sync_options)
    asset.seek_entity = Factory :study
    assert @util.should_follow_dependent(asset)

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

  test 'sync_external_asset refreshes dataset content and set sync status' do

    dataset1 = Seek::Openbis::Dataset.new(@endpoint, '20160210130454955-23')
    dataset2 = Seek::Openbis::Dataset.new(@endpoint, '20160215111736723-31')

    asset = OpenbisExternalAsset.build(dataset1)
    asset.synchronized_at = DateTime.now - 1.days
    asset.external_id = dataset2.perm_id
    asset.seek_entity = Factory :data_file

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

    data_file = Factory :data_file
    asset = OpenbisExternalAsset.build(dataset1)
    asset.synchronized_at = DateTime.now - 1.days
    asset.external_id = dataset2.perm_id

    asset.seek_entity = data_file

    assert_not_equal dataset2.perm_id, asset.content.perm_id

    assert asset.save

    Delayed::Job.destroy_all
    ReindexingQueue.destroy_all
    assert_difference('Delayed::Job.count', 1) do
      @util.sync_external_asset(asset)
    end
    assert ReindexingQueue.exists?(item: data_file)

    asset.reload
    Delayed::Job.destroy_all
    ReindexingQueue.destroy_all
    assert_no_difference('Delayed::Job.count') do
      # same content no change
      @util.sync_external_asset(asset)
    end
    refute ReindexingQueue.exists?(item: data_file)
  end

  test 'sync_external_asset links datasets to assay if follow links' do

    refute @zample.dataset_ids.empty?

    assay = Factory :assay

    assert assay.data_files.empty?

    asset = OpenbisExternalAsset.build(@zample)
    asset.sync_options = { link_datasets: '1' }
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
    asset.sync_options = { link_datasets: '0' }
    asset.sync_state = :refresh
    asset.seek_entity = assay

    @util.sync_external_asset(asset)

    assert asset.synchronized?
    assert assay.data_files.empty?

  end

  test 'sync_external_asset does not link to study if sync_options not set' do

    refute @experiment.dataset_ids.empty?
    refute @experiment.sample_ids.empty?

    study = Factory :study

    assert study.assays.empty?
    assert study.related_data_files.empty?

    asset = OpenbisExternalAsset.build(@experiment)
    asset.sync_options = { link_datasets: '0' }
    asset.seek_entity = study

    @util.sync_external_asset(asset)

    study.reload
    assert asset.synchronized?
    assert study.assays.empty?
    assert study.related_data_files.empty?
  end

  test 'sync_external_asset links to study if sync_options set' do

    refute @experiment.dataset_ids.empty?
    refute @experiment.sample_ids.empty?

    study = Factory :study

    assert study.assays.empty?
    assert study.related_data_files.empty?

    asset = OpenbisExternalAsset.build(@experiment)
    asset.sync_options = { link_datasets: '1' }
    asset.seek_entity = study

    @util.sync_external_asset(asset)

    study.reload
    assert asset.synchronized?
    assert_equal 1, study.assays.size # the fake files assay
    assert_equal @experiment.dataset_ids.size, study.related_data_files.size

    asset.sync_options = { link_datasets: '1', linked_assays: @experiment.sample_ids }
    @util.sync_external_asset(asset)

    study.reload
    assert_equal @experiment.sample_ids.size+1, study.assays.size # one extra for linking datasets
    assert_equal @experiment.dataset_ids.size, study.related_data_files.size

  end


  test 'follow_dependent links datasets to assay' do

    refute @zample.dataset_ids.empty?

    assay = Factory :assay

    assert assay.data_files.empty?

    asset = OpenbisExternalAsset.build(@zample)
    asset.sync_options = { link_datasets: '1' }
    asset.seek_entity = assay
    asset.save!

    errs = @util.follow_dependent(asset)
    assert_equal [], errs

    refute assay.data_files.empty?
    assert_equal @zample.dataset_ids.length, assay.data_files.length

  end

  ## --------- linking datasets to assay ---------- ##


  test 'associate_data_sets links datasets with assay creating new datafiles if necessary' do


    assay = Factory :assay

    df0 = Factory :data_file
    assay.associate(df0)
    assert df0.persisted?
    assert_equal 1, assay.data_files.length


    datasets = Seek::Openbis::Dataset.new(@endpoint).find_by_perm_ids(["20171002172401546-38", "20171002190934144-40", "20171004182824553-41"])
    assert_equal 3, datasets.length

    df1 = @util.createObisDataFile({}, @user, OpenbisExternalAsset.build(datasets[0]))
    assert df1.save

    assert_difference('AssayAsset.count', 3) do
      assert_difference('DataFile.count', 2) do
        assert_difference('ExternalAsset.count', 2) do

          assert_equal [], @util.associate_data_sets(assay, datasets)
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

          assert_equal [], @util.associate_data_sets_ids(assay, data_sets_ids, @endpoint)
        end
      end
    end

    assay.reload
    assert_equal 4, assay.data_files.length

  end

  ## --------- linking datasets to assay end ---------- ##

  ## --------- linking assays to study ---------- ##
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

  test 'associate_zamples_as_assays links datafiles to assays under the study if selected so' do


    study = Factory :study

    assert study.assays.empty?

    zamples = Seek::Openbis::Zample.new(@endpoint).find_by_perm_ids(['20171002172111346-37', '20171002172639055-39'])
    assert_equal 2, zamples.length

    ds_count = zamples.map { |z| z.dataset_ids }
                   .flatten.length

    assert ds_count > 0

    sync_options = { link_datasets: '1' }

    assert_difference('Assay.count', 2) do
      assert_difference('AssayAsset.count', ds_count) do
        assert_difference('DataFile.count', ds_count) do
          assert_difference('ExternalAsset.count', 2+ds_count) do

            assert_equal [], @util.associate_zamples_as_assays(study, zamples, sync_options)
          end
        end
      end
    end


    study.reload
    assert_equal 2, study.assays.count
    assert_equal ds_count, study.related_data_files.count

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

  test 'associate_zamples_as_assays sets sync_options for new assays and leaves existing untouched' do


    study = Factory :study

    assert study.assays.empty?

    zamples = Seek::Openbis::Zample.new(@endpoint).find_by_perm_ids(['20171002172111346-37', '20171002172639055-39'])
    assert_equal 2, zamples.length

    assay2 = Factory :assay
    assay2.study = study

    ea = OpenbisExternalAsset.find_or_create_by_entity(zamples[0])
    org_sync_options = { tomek: 'yes' }
    ea.sync_options = org_sync_options
    assay2.external_asset = ea

    disable_authorization_checks do
      assert assay2.save
      assert ea.save
    end

    sync_options = { edin: 1 }
    issues = []
    assert_difference('Assay.count', 1) do
      issues =@util.associate_zamples_as_assays(study, zamples, sync_options)
    end

    assert issues.empty?
    study.reload

    assay2 = study.assays.first
    assert_equal org_sync_options, assay2.external_asset.sync_options

    assay_new = study.assays.last
    assert_equal sync_options, assay_new.external_asset.sync_options


  end

  ## --------- linking assays to study end ---------- ##

  ## --------- follow_study_dependent_assays ---------- ##

  test 'follow_study_dependent_assays registers assays if set so' do

    study = Factory :study
    assert study.assays.empty?
    refute @experiment.sample_ids.empty?

    # no linking
    sync_options = {}
    issues = @util.follow_study_dependent_assays(@experiment, study, sync_options)

    assert_equal [], issues

    study.reload
    assert study.assays.empty?

    # automated assays linking
    assert(@experiment.sample_ids.length > 1)
    sync_options = { link_assays: '1' }
    issues = @util.follow_study_dependent_assays(@experiment, study, sync_options)

    assert_equal [], issues

    study.reload
    assert_equal @experiment.sample_ids.length, study.assays.count

  end

  test 'follow_study_dependent_assays registers selected assays if set so' do

    study = Factory :study
    assert study.assays.empty?
    assert(@experiment.sample_ids.length > 1)

    # selected assays
    sync_options = { linked_assays: [@experiment.sample_ids[0]] }
    issues = @util.follow_study_dependent_assays(@experiment, study, sync_options)

    assert_equal [], issues

    study.reload
    assert_equal 1, study.assays.count

  end

  test 'follow_study_dependent_assays registers assays with unique titles' do

    study = Factory :study
    assert study.assays.empty?
    assert @experiment.sample_ids.size > 1


    # automated assays linking
    sync_options = { link_assays: '1' }
    issues = @util.follow_study_dependent_assays(@experiment, study, sync_options)

    assert_equal [], issues

    study.reload
    assert_equal @experiment.sample_ids.length, study.assays.count
    titles = study.assays.map(&:title).uniq
    assert_equal @experiment.sample_ids.length, titles.length
  end

  ## --------- follow_study_dependent_assays end ---------- ##

  ## --------- follow_study_dependent_datafiles ---------- ##

  test 'follow_study_dependent_datafiles registers datafiles under fake assay if said so' do

    study = Factory :study
    assert study.assays.empty?
    assert study.related_data_files.empty?
    refute @experiment.dataset_ids.empty?

    sync_options = {}

    issues = @util.follow_study_dependent_datafiles(@experiment, study, sync_options)

    assert_equal [], issues

    study.reload
    assert study.assays.empty?
    assert study.related_data_files.empty?

    sync_options = { link_datasets: '1' }
    issues = @util.follow_study_dependent_datafiles(@experiment, study, sync_options)

    assert_equal [], issues

    study.reload
    assert_equal @experiment.dataset_ids.length, study.related_data_files.count
    assert_equal 'OpenBIS FILES', study.assays.first!.title
    assert_equal @experiment.dataset_ids.length, study.assays.first!.data_files.count

  end

  test 'follow_study_dependent_datafiles registers selected datafiles under fake assay if said so' do

    study = Factory :study
    assert study.assays.empty?
    assert study.related_data_files.empty?
    refute @experiment.dataset_ids.empty?


    sync_options = { linked_datasets: [@experiment.dataset_ids[1]] }
    issues = @util.follow_study_dependent_datafiles(@experiment, study, sync_options)

    assert_equal [], issues

    study.reload
    assert_equal 1, study.related_data_files.count
    assert_equal 'OpenBIS FILES', study.assays.first!.title

  end

  test 'follow_study_dependent_datafiles registers datafiles with unique names' do

    study = Factory :study
    assert study.assays.empty?
    assert study.related_data_files.empty?
    assert @experiment.dataset_ids.size > 1

    sync_options = { link_datasets: '1' }
    issues = @util.follow_study_dependent_datafiles(@experiment, study, sync_options)

    assert_equal [], issues

    study.reload
    assert_equal @experiment.dataset_ids.length, study.related_data_files.count

    titles = study.related_data_files.map(&:title).uniq
    assert_equal @experiment.dataset_ids.length, titles.length

  end


  ## --------- follow_study_dependent_datafiles end ---------- ##

  ## --------- follow_assay ---------- ##

  test 'follow assay registers all dependent datasets if set so' do
    #puts @zample.dataset_ids

    assay = Factory :assay
    es = OpenbisExternalAsset.find_or_create_by_entity(@zample)
    es.sync_options = { link_datasets: '1' }
    assay.external_asset = es

    assert assay.save
    assert assay.data_files.empty?
    refute @zample.dataset_ids.empty?

    issues = @util.follow_assay_dependent(assay)
    assert issues.empty?

    assert_equal @zample.dataset_ids.count, assay.data_files.count
  end

  test 'follow assay registers selected detasets' do
    #puts @zample.dataset_ids

    assay = Factory :assay
    es = OpenbisExternalAsset.find_or_create_by_entity(@zample)
    es.sync_options = { linked_datasets: [@zample.dataset_ids[1]] }
    assay.external_asset = es

    assert assay.save
    assert assay.data_files.empty?

    issues = @util.follow_assay_dependent(assay)
    assert issues.empty?

    assert_equal 1, assay.data_files.count
  end

  test 'follow assay registers dependent datasets with unique names' do

    assay = Factory :assay
    es = OpenbisExternalAsset.find_or_create_by_entity(@zample)
    es.sync_options = { link_datasets: '1' }
    assay.external_asset = es

    assert assay.save
    assert assay.data_files.empty?
    assert @zample.dataset_ids.size > 1

    issues = @util.follow_assay_dependent(assay)
    assert issues.empty?

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

    sync_options = { link_datasets: '1' }
    assert_same @zample.dataset_ids, @util.extract_requested_sets(@zample, sync_options)

    sync_options = { link_datasets: '1', linked_datasets: ['123'] }
    assert_same @zample.dataset_ids, @util.extract_requested_sets(@zample, sync_options)

  end

  test 'extract_requested_sets gives only selected sets that belongs to zample' do

    sync_options = {}

    assert_equal 3, @zample.dataset_ids.length

    assert_equal [], @util.extract_requested_sets(@zample, sync_options)

    sync_options = { linked_datasets: [] }
    assert_equal [], @util.extract_requested_sets(@zample, sync_options)

    sync_options = { linked_datasets: ['123'] }
    assert_equal [], @util.extract_requested_sets(@zample, sync_options)

    sync_options = { linked_datasets: ['123', @zample.dataset_ids[0]] }
    assert_equal [@zample.dataset_ids[0]], @util.extract_requested_sets(@zample, sync_options)

    sync_options = { linked_datasets: @zample.dataset_ids }
    assert_equal @zample.dataset_ids, @util.extract_requested_sets(@zample, sync_options)

  end

  test 'filter_assay_like_zamples returns ids of only samples marked as assays in openbis types' do
    ids = ["20171002172111346-37", "20171002172639055-39", "20171121152441898-53"]
    zamples = Seek::Openbis::Zample.new(@endpoint).find_by_perm_ids(ids)

    @endpoint.assay_types = ['TZ_FAIR_ASSAY']
    #, EXPERIMENTAL_STEP
    corr = @util.filter_assay_like_zamples(zamples, @endpoint)
    assert_equal 2, corr.length
    assert_equal ["20171002172111346-37", "20171002172639055-39"], corr.map(&:perm_id)
  end

  test 'extract_requested_zamples gives all assay-like zamples if linked is selected' do

    assert_equal 2, @experiment.sample_ids.length
    sync_options = {}

    assert_equal [], @util.extract_requested_assays(@experiment, sync_options)

    sync_options = { link_assays: '1' }
    assert_equal @experiment.sample_ids, @util.extract_requested_assays(@experiment, sync_options).map(&:perm_id)

    sync_options = { link_assays: '1', linked_zamples: ['123'] }
    assert_equal @experiment.sample_ids, @util.extract_requested_assays(@experiment, sync_options).map(&:perm_id)

  end

  test 'extract_requested_zamples gives only selected zamples that belongs to exp' do


    sync_options = {}

    assert_equal 2, @experiment.sample_ids.length

    assert_equal [], @util.extract_requested_assays(@experiment, sync_options)

    sync_options = { linked_assays: [] }
    assert_equal [], @util.extract_requested_assays(@experiment, sync_options).map(&:perm_id)

    sync_options = { linked_assays: ['123'] }
    assert_equal [], @util.extract_requested_assays(@experiment, sync_options).map(&:perm_id)

    sync_options = { linked_assays: ['123', @experiment.sample_ids[0]] }
    assert_equal [@experiment.sample_ids[0]], @util.extract_requested_assays(@experiment, sync_options).map(&:perm_id)

    sync_options = { linked_assays: @experiment.sample_ids }
    assert_equal @experiment.sample_ids, @util.extract_requested_assays(@experiment, sync_options).map(&:perm_id)

  end

  test 'fake_file_assay gives first assay of the openbis name' do

    disable_authorization_checks do

      study = Factory :study
      assay1 = Factory :assay
      assay1.title = 'Cos'
      assay1.study = study
      assert assay1.save

      assay2 = Factory :assay
      assay2.title = 'OpenBIS FILES'
      assay2.study = study
      assert assay2.save

      assert_equal assay2, @util.fake_file_assay(study)

    end
  end

  test 'fake_file_assay creates assay of the openbis name if missing' do


    study = Factory :study
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
    dj['code']='123'
    val = { 'datasets' => [dj] }

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
    codes = types.map { |t| t.code }
    assert_equal ['TZ_FAIR_ASSAY', 'UNKNOWN'], codes
  end

  test 'assay_types gives types configured as assays in the endpoint' do

    @endpoint.assay_types = 'EXPERIMENTAL_STEP'
    refute @endpoint.assay_types.empty?
    types = @util.assay_types(@endpoint, false)
    assert types
    codes = types.map { |t| t.code }
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
    codes = types.map { |t| t.code }
    assert_equal ['TZ_FAIR_ASSAY', 'UNKNOWN', 'EXPERIMENTAL_STEP'], codes
  end

  test 'study_types gives experiments types configured in endpoint' do

    refute @endpoint.study_types.empty?
    types = @util.study_types(@endpoint)
    assert types
    codes = types.map { |t| t.code }
    assert_equal ['DEFAULT_EXPERIMENT'], codes

    @endpoint.study_types = []
    types = @util.study_types(@endpoint)
    assert types.empty?
  end

  test 'dataset_types gives all dataset types' do
    types = @util.dataset_types(@endpoint)
    assert types
    codes = types.map { |t| t.code }
    assert_equal 7, codes.size
    assert_includes codes, 'TZ_FAIR'
  end
end
