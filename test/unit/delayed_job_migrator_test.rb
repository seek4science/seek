require 'test_helper'

class DelayedJobMigratorTest < ActiveSupport::TestCase
  def setup
    Delayed::Job.delete_all
    SolidQueue::Job.delete_all
    SolidQueue::ReadyExecution.delete_all
    SolidQueue::ScheduledExecution.delete_all
    ReindexingQueue.delete_all
    @previous_delay_jobs = Delayed::Worker.delay_jobs
    Delayed::Worker.delay_jobs = true # ensure enqueue writes a row rather than running inline
  end

  def teardown
    Delayed::Worker.delay_jobs = @previous_delay_jobs
  end

  test 'migrates a pending job into Solid Queue preserving queue, priority and run_at' do
    run_at = 5.minutes.from_now
    job = build_job(AuthLookupUpdateJob.new, queue: 'authlookup', priority: 3)
    dj = create_delayed_job(job, run_at: run_at)

    result = Seek::DelayedJobMigrator.run

    assert_equal 1, result.migrated
    assert_equal 0, Delayed::Job.count
    assert_equal 1, SolidQueue::Job.count

    sq = SolidQueue::Job.last
    assert_equal 'AuthLookupUpdateJob', sq.class_name
    assert_equal 'authlookup', sq.queue_name
    assert_equal 3, sq.priority
    assert_equal job.job_id, sq.active_job_id
    assert_in_delta run_at.to_f, sq.scheduled_at.to_f, 1
    assert_equal 'AuthLookupUpdateJob', sq.arguments['job_class']
    refute Delayed::Job.exists?(dj.id)
  end

  test 'a past-due job becomes ready and a future job stays scheduled' do
    due = build_job(AuthLookupUpdateJob.new, queue: 'authlookup', priority: 3)
    later = build_job(AuthLookupUpdateJob.new, queue: 'authlookup', priority: 3)
    due_dj = create_delayed_job(due, run_at: 5.minutes.ago)
    later_dj = create_delayed_job(later, run_at: 5.minutes.from_now)

    Seek::DelayedJobMigrator.run

    due_sq = SolidQueue::Job.find_by(active_job_id: due.job_id)
    later_sq = SolidQueue::Job.find_by(active_job_id: later.job_id)

    assert SolidQueue::ReadyExecution.exists?(job_id: due_sq.id), 'past-due job should be ready to run'
    assert SolidQueue::ScheduledExecution.exists?(job_id: later_sq.id), 'future job should stay scheduled'
    refute Delayed::Job.exists?(due_dj.id)
    refute Delayed::Job.exists?(later_dj.id)
  end

  test 'folds the delayed_job attempts count into ActiveJob executions' do
    job = build_job(AuthLookupUpdateJob.new, queue: 'authlookup', priority: 3)
    create_delayed_job(job, attempts: 2)

    Seek::DelayedJobMigrator.run

    assert_equal 2, SolidQueue::Job.last.arguments['executions']
  end

  test 'deletes already-failed rows instead of migrating them' do
    ok = build_job(AuthLookupUpdateJob.new, queue: 'authlookup', priority: 3)
    failed = build_job(AuthLookupUpdateJob.new, queue: 'authlookup', priority: 3)
    create_delayed_job(ok)
    failed_dj = create_delayed_job(failed, failed_at: 1.hour.ago)

    result = Seek::DelayedJobMigrator.run

    assert_equal 1, result.migrated
    assert_equal 1, result.failed_deleted
    assert_equal 0, Delayed::Job.count
    assert_equal 1, SolidQueue::Job.count
    assert_equal ok.job_id, SolidQueue::Job.last.active_job_id
    refute Delayed::Job.exists?(failed_dj.id)
  end

  test 'drops queued reindexing jobs instead of migrating them (reindex_all supersedes them)' do
    keep = build_job(AuthLookupUpdateJob.new, queue: 'authlookup', priority: 3)
    reindex_all = build_job(ReindexAllJob.new('DataFile'))
    reindexing = build_job(ReindexingJob.new)
    create_delayed_job(keep)
    create_delayed_job(reindex_all)
    create_delayed_job(reindexing)

    result = Seek::DelayedJobMigrator.run

    assert_equal 1, result.migrated
    assert_equal 2, result.reindex_dropped
    assert_equal 0, Delayed::Job.count
    assert_equal 1, SolidQueue::Job.count
    assert_equal keep.job_id, SolidQueue::Job.last.active_job_id
    assert_empty SolidQueue::Job.where(class_name: %w[ReindexAllJob ReindexingJob])
  end

  test 'clears the ReindexingQueue (superseded by reindex_all)' do
    sop = FactoryBot.create(:sop)
    document = FactoryBot.create(:document)
    ReindexingQueue.delete_all # ignore anything auto-enqueued when the records were created
    with_config_value(:solr_enabled, true) do
      ReindexingQueue.enqueue(sop, document, queue_job: false)
    end
    assert_equal 2, ReindexingQueue.count

    result = Seek::DelayedJobMigrator.run

    assert_equal 2, result.reindex_queue_cleared
    assert_equal 0, ReindexingQueue.count
  end

  test 'migrates a job whose argument record has since been deleted without raising' do
    content_blob = FactoryBot.create(:content_blob)
    job = build_job(RemoteContentFetchingJob.new(content_blob))
    create_delayed_job(job)
    # the referenced record is gone by the time the migration runs
    ContentBlob.where(id: content_blob.id).delete_all

    result = nil
    assert_nothing_raised { result = Seek::DelayedJobMigrator.run }

    assert_equal 1, result.migrated
    assert_equal 0, Delayed::Job.count
    sq = SolidQueue::Job.last
    assert_equal 'RemoteContentFetchingJob', sq.class_name
    # the dangling GlobalID is preserved verbatim; it is only resolved (and handled) when run
    assert_match(/ContentBlob\/#{content_blob.id}/, sq.arguments['arguments'].to_s)
  end

  test 'is a no-op when there are no delayed jobs' do
    result = Seek::DelayedJobMigrator.run

    assert_equal 0, result.migrated
    assert_equal 0, result.failed_deleted
    assert_equal 0, SolidQueue::Job.count
  end

  private

  def build_job(active_job, queue: nil, priority: nil)
    active_job.queue_name = queue if queue
    active_job.priority = priority if priority
    active_job
  end

  def create_delayed_job(active_job, run_at: 5.minutes.from_now, attempts: 0, failed_at: nil)
    wrapper = ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.new(active_job.serialize)
    dj = Delayed::Job.enqueue(wrapper, queue: active_job.queue_name, priority: active_job.priority, run_at: run_at)
    dj.update_columns(attempts: attempts) unless attempts.zero?
    dj.update_columns(failed_at: failed_at) if failed_at
    dj
  end
end
