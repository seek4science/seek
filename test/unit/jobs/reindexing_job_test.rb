require 'test_helper'

class ReindexingJobTest < ActiveSupport::TestCase
  test 'add item to queue' do
    p = FactoryBot.create :person
    ReindexingQueue.delete_all
    assert_enqueued_jobs(1, only: ReindexingJob) do
      assert_difference('ReindexingQueue.count') do
        ReindexingQueue.enqueue(p)
      end
    end

    models = [FactoryBot.create(:model), FactoryBot.create(:model)]
    ReindexingQueue.delete_all
    assert_enqueued_jobs(1, only: ReindexingJob) do
      assert_difference('ReindexingQueue.count', 2) do
        ReindexingQueue.enqueue(models)
      end
    end

    models = [FactoryBot.create(:model), FactoryBot.create(:model)]
    ReindexingQueue.delete_all
    assert_no_enqueued_jobs(only: ReindexingJob) do
      assert_difference('ReindexingQueue.count', 2) do
        ReindexingQueue.enqueue(models, queue_job: false)
      end
    end
  end

  test 'dont add items if search disabled' do
    p = FactoryBot.create :person
    ReindexingQueue.delete_all

    with_config_value(:solr_enabled, false) do
      assert_no_enqueued_jobs(only: ReindexingJob) do
        assert_no_difference('ReindexingQueue.count') do
          ReindexingQueue.enqueue(p)
          ReindexingQueue.enqueue(FactoryBot.create(:sop))
        end
      end
    end
  end

  test 'gather_items strips deleted (nil) items' do
    model1 = FactoryBot.create(:model)
    model2 = FactoryBot.create(:model)
    document = FactoryBot.create(:document)
    ReindexingQueue.delete_all
    ReindexingQueue.enqueue([model1, model2], queue_job: false)
    ReindexingQueue.enqueue(document, queue_job: false)

    disable_authorization_checks { model1.destroy! }

    items = ReindexingJob.new.gather_items

    assert_equal 2, items.length
    assert_not_includes items, model1
    assert_includes items, model2
    assert_includes items, document
  end

  test 'follow on job' do
    ReindexingQueue.delete_all
    refute ReindexingJob.new.follow_on_job?
    ReindexingQueue.enqueue(FactoryBot.create(:sop))
    assert ReindexingJob.new.follow_on_job?
    with_config_value(:solr_enabled, false) do
      refute ReindexingJob.new.follow_on_job?
    end
  end
end
