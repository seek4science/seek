require 'test_helper'

class ReindexingJobTest < ActiveSupport::TestCase

  test "exists" do
    Delayed::Job.delete_all
    assert !ReindexingJob.exists?
    assert_difference("Delayed::Job.count",1) do
      Delayed::Job.enqueue ReindexingJob.new
    end

    assert ReindexingJob.exists?
    job=Delayed::Job.first
    assert_nil job.locked_at
    job.locked_at = Time.now
    job.save!
    assert !ReindexingJob.exists?,"Should ignore locked jobs"
    
    Delayed::Job.delete_all

  end

end