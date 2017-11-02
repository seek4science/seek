require 'test_helper'
require 'openbis_test_helper'

class OpenbisSynJobTest < ActiveSupport::TestCase

  def setup
    @batch_size = 3;
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
      asset.synchronized_at= DateTime.now - (i*10).minutes
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
    assert_equal [assets[9], assets[7], assets[6]], needs

    (0..8).each do |i|
      assets[i].synchronized_at= DateTime.now
      assets[i].save
    end

    needs = @job.needs_refresh.to_a
    assert_equal [assets[9]], needs
  end

  test 'follow_on_delay gives one second if some work left or endpoint default otherwise' do

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

  test 'create initial jobs creates jobs for each endpoint' do
    endpoint2 = Factory(:openbis_endpoint, refresh_period_mins: 60, space_perm_id: 'API-SPACE2')

    assert endpoint2.save
    assert_equal 2, OpenbisEndpoint.count

    assert_difference('Delayed::Job.count', 2) do
      OpenbisSyncJob.create_initial_jobs
    end

    assert OpenbisSyncJob.new(@endpoint).exists?
    assert OpenbisSyncJob.new(endpoint2).exists?

  end

end