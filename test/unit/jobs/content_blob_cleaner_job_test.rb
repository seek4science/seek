require 'test_helper'

class ContentBlobCleanerJobTest < ActiveSupport::TestCase
  def setup
    @job = ContentBlobCleanerJob.new
    ContentBlob.destroy_all
    Delayed::Job.destroy_all
  end

  test 'defaults' do
    assert @job.follow_on_job?
    assert_equal 3, @job.default_priority
    assert_equal 8.hours, @job.follow_on_delay
    refute @job.allow_duplicate_jobs?
    assert_equal 8.hours, @job.grace_period
  end

  test 'create initial job' do
    assert_difference('Delayed::Job.count') do
      ContentBlobCleanerJob.create_initial_job
    end

    assert_equal ContentBlobCleanerJob, Delayed::Job.last.payload_object.class

    assert_no_difference('Delayed::Job.count') do
      ContentBlobCleanerJob.create_initial_job
    end
  end

  test 'perform' do
    to_go, keep1, keep2, keep3, keep4 = nil
    travel_to(9.hours.ago) do
      to_go = Factory(:content_blob)
      keep1 = Factory(:data_file).content_blob
      keep2 = Factory(:investigation).create_snapshot.content_blob
      keep3 = Factory(:strain_sample_type).content_blob
    end

    travel_to(7.hours.ago) do
      keep4 = Factory(:content_blob)
    end

    assert_difference('ContentBlob.count', -1) do
      @job.perform
    end

    refute ContentBlob.exists?(to_go.id)
    assert ContentBlob.exists?(keep1.id)
    assert ContentBlob.exists?(keep2.id)
    assert ContentBlob.exists?(keep3.id)
    assert ContentBlob.exists?(keep4.id)
  end

  test 'queue job' do
    assert_difference('Delayed::Job.count') do
      ContentBlobCleanerJob.new.queue_job
    end

    assert_equal ContentBlobCleanerJob, Delayed::Job.last.payload_object.class

    assert_no_difference('Delayed::Job.count') do
      ContentBlobCleanerJob.new.queue_job
    end

    Delayed::Job.last.update_attribute(:locked_at, Time.now)

    assert_no_difference('Delayed::Job.count') do
      ContentBlobCleanerJob.new.queue_job
    end
  end

  test 'exists?' do
    refute @job.exists?

    ContentBlobCleanerJob.new.queue_job

    assert @job.exists?

    Delayed::Job.last.update_attribute(:locked_at, Time.now)

    assert @job.exists?
  end
end
