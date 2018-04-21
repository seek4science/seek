require 'test_helper'
require 'openbis_test_helper'

class OpenbisSynJobTest < ActiveSupport::TestCase

  def setup
    mock_openbis_calls

    @batch_size = 3;
    #@endpoint = Factory(:openbis_endpoint)
    @endpoint = Factory(:openbis_endpoint, refresh_period_mins: 60)
    @job = OpenbisSyncJob.new(@endpoint, @batch_size)
    Delayed::Job.destroy_all # avoids jobs created from the after_create callback, this is tested for OpenbisEndpoint
  end

  test 'setup' do
    assert @endpoint
    assert @job
  end

  test 'needs_refresh gives oldest entries not synchronized yet and over the deadline' do

    assert @endpoint.save
    assets = []
    (1..10).each do |i|

      asset = ExternalAsset.new
      asset.seek_service = @endpoint
      asset.external_service = @endpoint.web_endpoint
      asset.external_id = i
      asset.sync_state = :refresh
      asset.synchronized_at= DateTime.now - (i*20).minutes
      assert asset.save
      assets << asset
    end


    assets[8].sync_state = :synchronized
    assets[8].save

    @endpoint.reload
    assert_equal 10, @endpoint.external_assets.count
    assert_equal 3, @batch_size

    needs = @job.needs_refresh.to_a
    assert needs
    #puts needs.map {|e| e.external_id}
    assert_equal 3, needs.length
    assert_equal [assets[9], assets[7], assets[6]], needs

    (0..8).each do |i|
      assets[i].synchronized_at= DateTime.now
      assets[i].save
    end

    needs = @job.needs_refresh.to_a
    assert_equal [assets[9]], needs
  end

  test 'needs_refresh gives priority to marked for refresh over the failed ones' do

    assert @endpoint.save
    assets = []
    (1..10).each do |i|

      asset = ExternalAsset.new
      asset.seek_service = @endpoint
      asset.external_service = @endpoint.web_endpoint
      asset.external_id = i
      asset.sync_state = :refresh
      asset.synchronized_at= DateTime.now - (i*20).minutes
      assert asset.save
      assets << asset
    end


    assets[8].sync_state = :synchronized
    assets[8].save

    assets[7].sync_state = :failed
    assets[7].save

    @endpoint.reload
    assert_equal 10, @endpoint.external_assets.count
    assert_equal 3, @batch_size

    needs = @job.needs_refresh.to_a
    assert needs
    #puts needs.map {|e| e.external_id}
    assert_equal 3, needs.length
    assert_equal [assets[9], assets[6], assets[5]], needs

    (0..7).each do |i|
      assets[i].sync_state = :failed
      assets[i].save
    end

    needs = @job.needs_refresh.to_a
    assert_equal [assets[9], assets[7], assets[6]], needs
  end

  test 'errorfree_needs_refresh gives oldest entries marked as refresh and over the deadline' do

    assert @endpoint.save
    assets = []
    (1..10).each do |i|

      asset = ExternalAsset.new
      asset.seek_service = @endpoint
      asset.external_service = @endpoint.web_endpoint
      asset.external_id = i
      asset.sync_state = :refresh
      asset.synchronized_at= DateTime.now - (i*20).minutes
      assert asset.save
      assets << asset
    end


    assets[8].sync_state = :synchronized
    assets[8].save

    assets[7].sync_state = :failed
    assets[7].save

    @endpoint.reload
    assert_equal 10, @endpoint.external_assets.count
    assert_equal 3, @batch_size

    needs = @job.needs_refresh.to_a
    assert needs
    #puts needs.map {|e| e.external_id}
    assert_equal 3, needs.length
    assert_equal [assets[9], assets[6], assets[5]], needs

    (0..8).each do |i|
      assets[i].synchronized_at= DateTime.now
      assets[i].save
    end

    needs = @job.needs_refresh.to_a
    assert_equal [assets[9]], needs
  end

  test 'follow_on_delay gives one second if marked refresh left or endpoint default otherwise' do

    assert @endpoint.save

    assert_equal @endpoint.refresh_period_mins.minutes, @job.follow_on_delay

    asset = ExternalAsset.new
    asset.seek_service = @endpoint
    asset.external_service = @endpoint.web_endpoint
    asset.external_id = 1
    asset.sync_state = :refresh
    asset.synchronized_at= DateTime.now - 100.minutes
    assert asset.save

    assert_equal 1.seconds, @job.follow_on_delay

  end

  test 'follow_on_delay gives 5 minutes if only failed left or endpoint default otherwise' do

    assert @endpoint.save

    assert_equal @endpoint.refresh_period_mins.minutes, @job.follow_on_delay

    asset = ExternalAsset.new
    asset.seek_service = @endpoint
    asset.external_service = @endpoint.web_endpoint
    asset.external_id = 1
    asset.sync_state = :failed
    asset.synchronized_at= DateTime.now - 100.minutes
    assert asset.save

    assert_equal 5.minutes, @job.follow_on_delay

  end

  test 'create initial jobs creates jobs for each endpoint' do
    endpoint2 = Factory(:openbis_endpoint, refresh_period_mins: 60, space_perm_id: 'API-SPACE2')

    assert endpoint2.save
    assert_equal 2, OpenbisEndpoint.count

    Delayed::Job.destroy_all
    assert_difference('Delayed::Job.count', 2) do
      OpenbisSyncJob.create_initial_jobs
    end

    assert OpenbisSyncJob.new(@endpoint).exists?
    assert OpenbisSyncJob.new(endpoint2).exists?

  end

  test 'perfom_job does nothing on synchronized assets' do

    assay = Factory :assay
    assert assay.data_files.empty?

    zample = Seek::Openbis::Zample.new(@endpoint, '20171002172111346-37')
    refute zample.dataset_ids.empty?

    asset = OpenbisExternalAsset.build(zample)
    asset.seek_entity = assay
    asset.synchronized_at = DateTime.now - 1.days

    assert asset.save
    old = asset.synchronized_at

    @job.perform_job(asset)

    asset.reload
    assert_equal old.to_date, asset.synchronized_at.to_date
    assert assay.data_files.empty?

  end

  test 'perfom_job refresh content and dependencies on non-synchronized assets' do

    assay = Factory :assay
    assert assay.data_files.empty?

    zample = Seek::Openbis::Zample.new(@endpoint, '20171002172111346-37')
    refute zample.dataset_ids.empty?

    asset = OpenbisExternalAsset.build(zample, { link_datasets: '1' })
    asset.seek_entity = assay
    asset.synchronized_at = DateTime.now - 1.days
    asset.sync_state = :refresh

    assert asset.save

    @job.perform_job(asset)

    asset.reload
    assay.reload

    assert asset.synchronized?
    assert_equal DateTime.now.to_date, asset.synchronized_at.to_date
    refute assay.data_files.empty?
    assert_equal zample.dataset_ids.length, assay.data_files.length
  end

  test 'seek_util created only once' do
    assert_same @job.seek_util, @job.seek_util
  end

end