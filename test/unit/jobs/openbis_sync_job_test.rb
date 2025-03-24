require 'test_helper'
require 'openbis_test_helper'

class OpenbisSyncJobTest < ActiveSupport::TestCase
  def setup
    FactoryBot.create :experimental_assay_class
    mock_openbis_calls

    @batch_size = 3
    @endpoint = FactoryBot.create(:openbis_endpoint, refresh_period_mins: 60)
    @endpoint.assay_types = ['TZ_FAIR_ASSAY', 'EXPERIMENTAL_STEP'] #needed for automatic picking up of assays
    assert @endpoint.save
    @job = OpenbisSyncJob.new(@endpoint, @batch_size)
    @person = FactoryBot.create(:person, project: @endpoint.project)
    User.current_user = nil # @person.user
  end

  test 'setup' do
    assert @endpoint
    assert @job
  end

  test 'checking that asset.save need to be followed by touch to update timestamp even if content not changed' do
    asset = ExternalAsset.new
    asset.seek_service = @endpoint
    asset.external_service = @endpoint.web_endpoint
    asset.external_id = 2
    asset.sync_state = :refresh
    asset.synchronized_at = DateTime.now - 20.minutes
    assert asset.save
    asset.reload

    mod = asset.updated_at

    asset = ExternalAsset.find(asset.id)
    assert_equal mod, asset.updated_at

    travel 1.seconds do
      asset.sync_state = :failed
      assert asset.save

      assert mod < asset.updated_at
      asset = ExternalAsset.find(asset.id)
      assert mod < asset.updated_at

      mod = asset.updated_at
    end

    travel 2.seconds do
      # update with same value
      asset.sync_state = :failed
      assert asset.save

      assert mod == asset.updated_at
      asset.touch
      asset = ExternalAsset.find(asset.id)
      assert mod < asset.updated_at

      mod = asset.updated_at
    end

    travel 3.seconds do
      assert asset.save

      assert mod == asset.updated_at
      asset.touch
      asset = ExternalAsset.find(asset.id)
      assert mod < asset.updated_at

      mod = asset.updated_at
    end
  end

  test 'need_sync gives not synchronized entries due to refresh sorted by last change (see bussiness rule)' do
    # bussines rule
    # - status refresh or failed
    # - synchronized_at before (Now - endpoint refresh)
    # - for failed: last update before (Now - endpont_refresh/2) to prevent constant checking of failed entries)
    # - fatal not returned

    @endpoint.refresh_period_mins = 121
    disable_authorization_checks do
      assert @endpoint.save
    end

    assets = []

    # those should be skipped as not overdue for refresh
    (0..4).each do |i|
      asset = ExternalAsset.new
      asset.seek_service = @endpoint
      asset.external_service = @endpoint.web_endpoint
      asset.external_id = i
      asset.sync_state = :refresh
      asset.synchronized_at = DateTime.now
      travel (-5 - i).days do
        assert asset.save
      end
      assets << asset
    end

    (5..9).each do |i|
      asset = ExternalAsset.new
      asset.seek_service = @endpoint
      asset.external_service = @endpoint.web_endpoint
      asset.external_id = i
      asset.sync_state = :refresh
      # this one should be skipped
      asset.sync_state = :synchronized if i == 8
      asset.synchronized_at = DateTime.now - 1.days
      travel (-i).hours do
        assert asset.save
      end
      assets << asset
    end

    @endpoint.reload
    assert_equal 10, @endpoint.external_assets.count
    assert_equal 3, @batch_size

    needs = @job.need_sync.to_a
    assert needs

    assert_equal 3, needs.length
    assert_equal [assets[9], assets[7], assets[6]], needs

    # reset update_at stamp so they will be reordered
    assets[9].touch

    needs = @job.need_sync.to_a
    assert_equal [assets[7], assets[6], assets[5]], needs
  end

  test 'need_sync gives priority to refresh over failed' do
    # bussines rule
    # - status different form synchronized
    # - synchronized_at before Now- endpoint refresh
    # - last update before Now - endpont_refresh/2 (to prevent constant checking of failed entries)

    @endpoint.refresh_period_mins = 121
    disable_authorization_checks do
      assert @endpoint.save
    end

    assets = []

    (0..5).each do |i|
      asset = ExternalAsset.new
      asset.seek_service = @endpoint
      asset.external_service = @endpoint.web_endpoint
      asset.external_id = i
      asset.sync_state = :failed
      # this one should be first
      asset.sync_state = :refresh if i == 2
      asset.synchronized_at = DateTime.now - 1.days
      travel (-2 - i).hours do
        assert asset.save
      end
      assets << asset
    end

    @endpoint.reload
    assert_equal 6, @endpoint.external_assets.count
    assert_equal 3, @batch_size

    needs = @job.need_sync.to_a
    assert needs

    assert_equal 3, needs.length
    assert_equal [assets[2], assets[5], assets[4]], needs
  end

  test 'need_sync ignores fatal or synchronized' do
    # bussines rule
    # - status different form synchronized
    # - synchronized_at before Now- endpoint refresh
    # - last update before Now - endpont_refresh/2 (to prevent constant checking of failed entries)

    @endpoint.refresh_period_mins = 121
    disable_authorization_checks do
      assert @endpoint.save
    end

    asset = ExternalAsset.new
    asset.seek_service = @endpoint
    asset.external_service = @endpoint.web_endpoint
    asset.external_id = 1
    asset.synchronized_at = DateTime.now - 1.days

    asset.sync_state = :fatal
    travel(-1.days) do
      assert asset.save
    end

    needs = @job.need_sync.to_a
    assert needs
    assert needs.empty?

    asset.sync_state = :synchronized
    travel -1.days do
      assert asset.save
    end

    needs = @job.need_sync.to_a
    assert needs
    assert needs.empty?

    asset.sync_state = :failed
    travel -1.days do
      assert asset.save
    end

    needs = @job.need_sync.to_a
    assert needs
    assert_equal [asset], needs
  end

  test 'follow_on_job? is true if marked refresh left or endpoint default otherwise' do
    assert @endpoint.save

    refute @job.follow_on_job?

    asset = ExternalAsset.new
    asset.seek_service = @endpoint
    asset.external_service = @endpoint.web_endpoint
    asset.external_id = 1
    asset.sync_state = :refresh
    asset.synchronized_at = DateTime.now - (@endpoint.refresh_period_mins + 5).minutes
    travel(-(@endpoint.refresh_period_mins + 5).minutes) do
      assert asset.save
    end

    assert @job.follow_on_job?
  end

  test 'queue_timed_jobs creates jobs for each endpoint needing sync' do
    endpoint2 = FactoryBot.create(:openbis_endpoint, refresh_period_mins: 60, space_perm_id: 'API-SPACE2')
    no_sync_needed = FactoryBot.create(:openbis_endpoint, refresh_period_mins: 60, last_sync: 2.seconds.ago)

    assert endpoint2.save
    assert @endpoint.due_sync?
    assert endpoint2.due_sync?
    refute no_sync_needed.due_sync?
    assert_equal 3, OpenbisEndpoint.count
    assert_equal 2, OpenbisEndpoint.all.select(&:due_sync?).count

    assert_enqueued_jobs(2, only: OpenbisSyncJob) do
      assert_enqueued_with(job: OpenbisSyncJob, args: [@endpoint]) do
        assert_enqueued_with(job: OpenbisSyncJob, args: [endpoint2]) do
          OpenbisSyncJob.queue_timed_jobs
        end
      end
    end
  end

  test 'sync job updates `last_sync` timestamp' do
    assert_nil @endpoint.last_sync

    OpenbisSyncJob.perform_now(@endpoint)

    refute_nil @endpoint.last_sync
  end

  test 'queue_timed_jobs does nothing if autosync disabled' do
    with_config_value(:openbis_autosync, false) do
      endpoint = FactoryBot.create(:openbis_endpoint, refresh_period_mins: 60)
      assert endpoint.due_sync?

      assert_no_enqueued_jobs(only: OpenbisSyncJob) do
        OpenbisSyncJob.queue_timed_jobs
      end
    end
  end

  test 'queue_timed_jobs does nothing if openbis disabled' do
    with_config_value(:openbis_enabled, false) do
      endpoint = FactoryBot.create(:openbis_endpoint, refresh_period_mins: 60)
      assert endpoint.due_sync?

      assert_no_enqueued_jobs(only: OpenbisSyncJob) do
        OpenbisSyncJob.queue_timed_jobs
      end
    end
  end

  test 'perform_job does nothing on synchronized assets' do
    assay = FactoryBot.create :assay, contributor: @person
    assert assay.data_files.empty?

    zample = Seek::Openbis::Zample.new(@endpoint, '20171002172111346-37')
    refute zample.dataset_ids.empty?

    asset = OpenbisExternalAsset.build(zample)
    asset.seek_entity = assay
    asset.synchronized_at = DateTime.now - 1.days

    assert asset.synchronized?
    assert asset.save
    old = asset.synchronized_at

    User.with_current_user(nil) do
      @job.perform_job(asset)
    end

    asset.reload
    assert_equal old.to_date, asset.synchronized_at.to_date
    assert assay.data_files.empty?
  end

  test 'perform_job refresh content and dependencies on non-synchronized assay like asset' do
    assay = FactoryBot.create :assay, contributor: @person
    assert_empty assay.data_files

    zample = Seek::Openbis::Zample.new(@endpoint, '20171002172111346-37')
    refute zample.dataset_ids.empty?

    asset = OpenbisExternalAsset.build(zample, link_datasets: '1', new_arrivals: '1')
    asset.seek_entity = assay
    asset.synchronized_at = DateTime.now - 1.days
    asset.sync_state = :refresh

    assert asset.save

    User.with_current_user(nil) do
      @job.perform_job(asset)
    end

    asset.reload
    assay.reload

    assert asset.synchronized?
    assert_equal DateTime.now.to_date, asset.synchronized_at.to_date

    refute_empty assay.data_files
    assert_equal zample.dataset_ids.length, assay.data_files.length
  end

  test 'perform_job refresh content and dependencies on non-synchronized study like asset' do
    study = FactoryBot.create :study, contributor: @person
    assert_empty study.assays
    assert_empty study.related_data_files

    experiment = Seek::Openbis::Experiment.new(@endpoint, '20171121152132641-51')
    refute experiment.sample_ids.empty?
    refute experiment.dataset_ids.empty?
    assert(experiment.sample_ids.length > 1)

    asset = OpenbisExternalAsset.build(experiment, link_assays: '1', link_datasets: '1', new_arrivals: '1')
    asset.seek_entity = study
    asset.synchronized_at = DateTime.now - 1.days
    asset.sync_state = :refresh

    assert asset.save


    User.with_current_user(nil) do
      @job.perform_job(asset)
    end

    asset.reload
    study.reload

    assert asset.synchronized?
    assert_equal DateTime.now.to_date, asset.synchronized_at.to_date

    refute_empty study.assays
    refute_empty study.related_data_files

    # one more cause there is fake assay for all the files
    assert_equal experiment.sample_ids.length + 1, study.assays.length
    assert_equal experiment.dataset_ids.length, study.related_data_files.length
  end


  test 'perform_job always update mod stamp even if no content change' do
    assay = FactoryBot.create :assay

    # normal sample
    zample = Seek::Openbis::Zample.new(@endpoint, '20171002172111346-37')

    asset = OpenbisExternalAsset.build(zample, {})
    asset.seek_entity = assay
    asset.synchronized_at = DateTime.now - 1.days
    asset.sync_state = :synchronized

    assert asset.save

    travel 1.second do
      mod = asset.updated_at

      User.with_current_user(nil) do
        @job.perform_job(asset)
      end

      asset.reload
      assert mod < asset.updated_at

    end
    travel 2.second do
      mod = asset.updated_at

      User.with_current_user(nil) do
        @job.perform_job(asset)
      end

      asset.reload
      assert mod < asset.updated_at
    end
  end

  test 'perform_job always update mod stamp even if errors' do
    assay = FactoryBot.create :assay, contributor: @person

    # normal sample
    zample = Seek::Openbis::Zample.new(@endpoint, '20171002172111346-37')
    json = zample.json.clone
    json['permId'] = 'XXX'

    # now the sample cannot be found
    zample = Seek::Openbis::Zample.new(@endpoint).populate_from_json(json)

    # checking if fetching sample gives error
    begin
      t = Seek::Openbis::Zample.new(@endpoint, zample.perm_id)
      refute t
    rescue => e
      assert e
    end
    asset = OpenbisExternalAsset.build(zample, {})
    asset.seek_entity = assay
    asset.synchronized_at = DateTime.now - 1.days
    asset.sync_state = :failed

    assert asset.save

    travel 1.second do
      mod = asset.updated_at
      User.with_current_user(nil) do
        @job.perform_job(asset)
      end
      asset.reload
      assert asset.failed?
      assert asset.err_msg
      assert mod < asset.updated_at
    end

    travel 2.second do
      mod = asset.updated_at
      User.with_current_user(nil) do
        @job.perform_job(asset)
      end
      asset.reload
      assert asset.failed?
      assert asset.err_msg
      assert mod < asset.updated_at
    end
  end

  test 'perform_job sets fatal if failures larger than threshold' do
    assay = FactoryBot.create :assay, contributor: @person

    # normal sample
    zample = Seek::Openbis::Zample.new(@endpoint, '20171002172111346-37')
    json = zample.json.clone
    json['permId'] = 'XXX'

    # now the sample cannot be found
    zample = Seek::Openbis::Zample.new(@endpoint).populate_from_json(json)

    # checking if fetching sample gives error
    begin
      t = Seek::Openbis::Zample.new(@endpoint, zample.perm_id)
      refute t
    rescue Exception => e
      assert e
    end

    asset = OpenbisExternalAsset.build(zample, {})
    asset.seek_entity = assay
    asset.synchronized_at = DateTime.now - 1.days
    asset.sync_state = :failed
    asset.failures = @job.failure_threshold

    assert asset.save

    User.with_current_user(nil) do
      @job.perform_job(asset)
    end
    asset.reload

    assert asset.fatal?
    assert asset.err_msg.start_with? 'Stopped sync: '
  end

  test 'failure_threshold can be reached in about two day' do
    disable_authorization_checks do
      @endpoint.refresh_period_mins = 60
      @endpoint.save!
      @job = OpenbisSyncJob.new(@endpoint, @batch_size)
      thresh = @job.failure_threshold
      assert 48 <= thresh
      assert 49 >= thresh
      assert thresh * @endpoint.refresh_period_mins >= (48 * 60)
      assert thresh * @endpoint.refresh_period_mins <= (49 * 60)

      @endpoint.refresh_period_mins = 125
      @endpoint.save!
      @job = OpenbisSyncJob.new(@endpoint, @batch_size)
      thresh = @job.failure_threshold
      assert thresh * @endpoint.refresh_period_mins >= (47 * 60)
      assert thresh * @endpoint.refresh_period_mins <= (49 * 60)
    end
  end

  test 'failure_threshold is at least 3' do
    disable_authorization_checks do
      @endpoint.refresh_period_mins = 60 * 50
      @endpoint.save!
      @job = OpenbisSyncJob.new(@endpoint, @batch_size)
      thresh = @job.failure_threshold
      assert thresh >= 3
    end
  end

end
