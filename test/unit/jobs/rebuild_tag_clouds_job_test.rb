require 'test_helper'

class RebuildTagCloudsJobTest < ActiveSupport::TestCase
  def setup
    Delayed::Job.destroy_all
  end

  def teardown
    Delayed::Job.destroy_all
  end

  test 'exists' do
    assert !RebuildTagCloudsJob.new.exists?
    assert_difference('Delayed::Job.count', 1) do
      Delayed::Job.enqueue RebuildTagCloudsJob.new
    end

    assert RebuildTagCloudsJob.new.exists?

    job = Delayed::Job.first
    assert_nil job.locked_at
    job.locked_at = Time.now
    job.save!
    assert !RebuildTagCloudsJob.new.exists?, 'Should ignore locked jobs'

    assert_nil job.failed_at
    job.failed_at = Time.now
    job.locked_at = nil
    job.save!
    assert !RebuildTagCloudsJob.new.exists?, 'Should ignore failed jobs'
  end

  test 'count' do
    assert_equal 0, RebuildTagCloudsJob.new.count

    Delayed::Job.enqueue RebuildTagCloudsJob.new

    assert_equal 1, RebuildTagCloudsJob.new.count

    job = Delayed::Job.first
    assert_nil job.locked_at
    job.locked_at = Time.now
    job.save!
    assert_equal 0, RebuildTagCloudsJob.new.count, 'Should ignore locked jobs'
  end

  test 'create job' do
    assert_equal 0, Delayed::Job.count
    RebuildTagCloudsJob.new.queue_job
    assert_equal 1, Delayed::Job.count

    job = Delayed::Job.first
    assert_equal 3, job.priority

    RebuildTagCloudsJob.new.queue_job
    assert_equal 1, Delayed::Job.count
  end

  test 'perform' do
    RebuildTagCloudsJob.new.perform
  end
end
