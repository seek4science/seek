require 'test_helper'

class RebuildTagCloudsJobTest < ActiveSupport::TestCase
  def setup
    Delayed::Job.destroy_all
  end

  def teardown
    Delayed::Job.destroy_all
  end

  test "exists" do
    assert !RebuildTagCloudsJob.exists?
    assert_difference("Delayed::Job.count",1) do
      Delayed::Job.enqueue RebuildTagCloudsJob.new
    end

    assert RebuildTagCloudsJob.exists?

    job=Delayed::Job.first
    assert_nil job.locked_at
    job.locked_at = Time.now
    job.save!
    assert !RebuildTagCloudsJob.exists?,"Should ignore locked jobs"
  end

  test "count" do
    assert_equal 0,RebuildTagCloudsJob.count

    Delayed::Job.enqueue RebuildTagCloudsJob.new


    assert_equal 1, RebuildTagCloudsJob.count

    job=Delayed::Job.first
    assert_nil job.locked_at
    job.locked_at = Time.now
    job.save!
    assert_equal 0, RebuildTagCloudsJob.count,"Should ignore locked jobs"
  end

  test "create job" do
    assert_equal 0,Delayed::Job.count
    RebuildTagCloudsJob.create_job
    assert_equal 1,Delayed::Job.count

    job = Delayed::Job.first
    assert_equal 2,job.priority

    RebuildTagCloudsJob.create_job
    assert_equal 1,Delayed::Job.count
  end

  test "perform" do
    RebuildTagCloudsJob.new.perform
  end

end