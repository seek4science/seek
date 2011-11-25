require 'test_helper'

class ReindexingJobTest < ActiveSupport::TestCase

  test "exists" do
    assert !ReindexingJob.exists?
    Delayed::Job.enqueue ReindexingJob.new
    assert ReindexingJob.exists?
    Delayed::Job.delete_all

  end

end