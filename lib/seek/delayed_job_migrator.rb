module Seek
  # One-off migration of any rows left in the `delayed_jobs` table (queued before the Solid Queue
  # cutover) into Solid Queue's own tables. Invoked exactly once via `seek:upgrade` - see the
  # `migrate_delayed_jobs_to_solid_queue` task in lib/tasks/seek_upgrades.rake.
  #
  # Pending and locked rows are re-enqueued onto Solid Queue, preserving queue, run_at, priority and
  # attempts. A stale lock (`locked_at`/`locked_by`) is ignored: by this point the delayed_job workers
  # are gone, so the lock is meaningless and the job simply needs running again. Rows that have
  # already failed (`failed_at` set) are deleted rather than migrated.
  #
  # Queued reindexing jobs (`ReindexAllJob`/`ReindexingJob`) are dropped rather than migrated, and the
  # `ReindexingQueue` table (which `ReindexingJob` pulls its batches from) is cleared: the upgrade runs
  # a full `seek:reindex_all` immediately afterwards, which re-enqueues a complete reindex of every
  # searchable type, so any reindex work queued before the cutover is redundant.
  #
  # The Solid Queue row is built directly from the raw ActiveJob payload (`job_data`) rather than by
  # deserialising and re-serialising the job. Re-serialising would force the job's GlobalID arguments
  # to be resolved, raising ActiveJob::DeserializationError - and aborting the whole migration - for
  # any job whose referenced record has since been deleted. Building the row directly keeps the
  # original serialised arguments intact; deserialisation then happens lazily when the worker runs the
  # job, where ApplicationJob's rescue_from already swallows a missing-record DeserializationError.
  class DelayedJobMigrator
    # Job classes whose queued work is made redundant by the full `seek:reindex_all` that the upgrade
    # runs immediately afterwards - dropped rather than migrated.
    REINDEX_JOB_CLASSES = %w[ReindexAllJob ReindexingJob].freeze

    Result = Struct.new(:migrated, :failed_deleted, :reindex_dropped, :reindex_queue_cleared, :skipped,
                        keyword_init: true) do
      def summary
        "#{migrated} migrated, #{failed_deleted} failed row(s) deleted, " \
          "#{reindex_dropped} reindex job(s) dropped, #{reindex_queue_cleared} reindex queue entry(s) cleared, " \
          "#{skipped} skipped"
      end
    end

    def self.run(logger: nil)
      new(logger: logger).run
    end

    def initialize(logger: nil)
      @logger = logger
    end

    def run
      result = Result.new(migrated: 0, failed_deleted: 0, reindex_dropped: 0, reindex_queue_cleared: 0,
                          skipped: 0)
      result.reindex_queue_cleared = clear_reindexing_queue

      return result unless delayed_jobs_available?

      Delayed::Job.find_each do |dj|
        if dj.failed_at.present?
          dj.destroy!
          result.failed_deleted += 1
          next
        end

        job_data = job_data_for(dj)

        if job_data.nil?
          result.skipped += 1
        elsif REINDEX_JOB_CLASSES.include?(job_data['job_class'])
          dj.destroy!
          result.reindex_dropped += 1
        elsif migrate(dj, job_data)
          result.migrated += 1
        else
          result.skipped += 1
        end
      end

      result
    end

    private

    def migrate(dj, job_data)
      ActiveRecord::Base.transaction do
        SolidQueue::Job.create!(
          queue_name: dj.queue.presence || job_data['queue_name'].presence || 'default',
          active_job_id: job_data['job_id'],
          priority: dj.priority || job_data['priority'] || 0,
          scheduled_at: dj.run_at,
          class_name: job_data['job_class'],
          arguments: job_data
        )
        dj.destroy!
      end
      true
    rescue StandardError => e
      log("Failed to migrate delayed_job #{dj.id} (#{job_data&.dig('job_class')}): #{e.class}: #{e.message}")
      false
    end

    # Extracts the ActiveJob payload hash from the delayed_job handler, folding the delayed_job
    # `attempts` count into ActiveJob's `executions` field. Returns nil for any row that isn't an
    # ActiveJob wrapper (SEEK only ever enqueues via ActiveJob, so this is a defensive guard).
    def job_data_for(dj)
      payload = dj.payload_object
      return nil unless payload.respond_to?(:job_data)

      job_data = payload.job_data.dup
      job_data['executions'] = [job_data['executions'].to_i, dj.attempts.to_i].max
      job_data
    rescue StandardError => e
      log("Could not read delayed_job #{dj.id} handler: #{e.class}: #{e.message}")
      nil
    end

    # Empties the ReindexingQueue - its pending batches are superseded by the full reindex_all the
    # upgrade runs next. Returns the number of entries removed.
    def clear_reindexing_queue
      return 0 unless defined?(ReindexingQueue) && ReindexingQueue.table_exists?

      ReindexingQueue.delete_all
    end

    def delayed_jobs_available?
      defined?(Delayed::Job) && ActiveRecord::Base.connection.table_exists?('delayed_jobs')
    end

    def log(message)
      @logger&.call(message)
    end
  end
end
