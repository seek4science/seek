require 'test_helper'

class ReindexingJobTest < ActiveSupport::TestCase
  test 'add item to queue' do
    p = Factory :person
    ReindexingQueue.delete_all
    assert_enqueued_jobs(1, only: ReindexingJob) do
      assert_difference('ReindexingQueue.count') do
        ReindexingQueue.enqueue(p)
      end
    end

    models = [Factory(:model), Factory(:model)]
    ReindexingQueue.delete_all
    assert_enqueued_jobs(1, only: ReindexingJob) do
      assert_difference('ReindexingQueue.count', 2) do
        ReindexingQueue.enqueue(models)
      end
    end

    models = [Factory(:model), Factory(:model)]
    ReindexingQueue.delete_all
    assert_no_enqueued_jobs(only: ReindexingJob) do
      assert_difference('ReindexingQueue.count', 2) do
        ReindexingQueue.enqueue(models, queue_job: false)
      end
    end
  end
end
