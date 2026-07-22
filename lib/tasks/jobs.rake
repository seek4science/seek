# frozen_string_literal: true

# Solid Queue replacements for the `jobs:*` rake tasks that delayed_job's railtie defines.
#
# The delayed_job gem is still installed (as a rollback safety net for the Solid Queue migration), so
# it still contributes `jobs:work`, `jobs:workoff`, `jobs:clear` and `jobs:check` - all of which now
# operate on the `delayed_jobs` table that nothing writes to any more. Rather than leave those as
# silent no-ops, they are cleared here and redefined against Solid Queue. Rake tasks contributed by
# gems are loaded before the application's own lib/tasks/*.rake, so the tasks are already defined by
# the time this file runs; the guard keeps it working once delayed_job is eventually removed.
%w[work workoff clear check].each do |name|
  Rake::Task["jobs:#{name}"].clear if Rake::Task.task_defined?("jobs:#{name}")
end

namespace :jobs do
  desc 'Start the Solid Queue supervisor (equivalent to bin/jobs)'
  task work: :environment do
    SolidQueue::Supervisor.start
  end

  desc 'Run all available Solid Queue jobs and exit when the queue is empty. QUEUES=a,b THREADS=n'
  task workoff: :environment do
    queues = ENV['QUEUES'].presence || ENV['QUEUE'].presence || '*'
    threads = (ENV['THREADS'].presence || 3).to_i

    # Move any scheduled jobs that are already due onto the ready queue - normally the dispatcher's
    # job, but there isn't one running here. Only due jobs are picked up, so anything scheduled for
    # the future is deliberately left alone. Jobs that were already ready need no dispatching, so this
    # is routinely zero even when there is plenty of work waiting.
    dispatched = 0
    loop do
      batch = SolidQueue::ScheduledExecution.dispatch_next_batch(500)
      dispatched += batch
      break if batch.zero?
    end

    waiting = SolidQueue::ReadyExecution.count
    puts "Dispatched #{dispatched} due scheduled job(s); #{waiting} job(s) ready to run on queue(s) #{queues}"

    # Count what actually runs. Solid Queue doesn't report this itself, and the job rows can't simply be
    # counted afterwards: jobs may enqueue further jobs, and a job that fails is left unfinished. Note
    # that the exception count stays at zero for SEEK's own jobs however badly they go wrong, because
    # ApplicationJob's `rescue_from(Exception)` handles the exception inside `perform_now` - it is only
    # reached by jobs that don't inherit from ApplicationJob, such as SolidQueue::RecurringJob.
    performed = Concurrent::AtomicFixnum.new
    failed = Concurrent::AtomicFixnum.new
    subscriber = ActiveSupport::Notifications.subscribe('perform.active_job') do |*, payload|
      performed.increment
      failed.increment if payload[:exception] || payload[:exception_object]
    end

    started_at = Time.now
    begin
      # A worker in `inline` mode runs in the current process and shuts itself down as soon as the ready
      # queue is empty, waiting for its thread pool to drain first - which is exactly delayed_job's
      # `workoff` behaviour. Jobs enqueued by the jobs being run are only picked up if they land before
      # the queue empties, again matching delayed_job.
      worker = SolidQueue::Worker.new(queues: queues, threads: threads, polling_interval: 0.1)
      worker.mode = :inline
      worker.start
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    summary = "Ran #{performed.value} job(s) in #{(Time.now - started_at).round(1)}s"
    summary += ", #{failed.value} raised an exception" if failed.value.positive?
    puts summary
    puts "#{SolidQueue::Job.where(finished_at: nil).count} unfinished job(s) remain (including any scheduled for later)"
  end

  desc 'Clear the Solid Queue queue by discarding every unfinished job'
  task clear: :environment do
    count = 0
    SolidQueue::Job.where(finished_at: nil).find_each do |job|
      job.discard
      count += 1
    end
    puts "Discarded #{count} unfinished job(s)"
  end

  desc "Exit with error status if any jobs older than max_age seconds haven't been run yet"
  task :check, [:max_age] => :environment do |_task, args|
    args.with_defaults(max_age: 300)

    # Measured from when the job became due rather than when it was created, so that jobs deliberately
    # scheduled for later aren't reported as overdue.
    unfinished = SolidQueue::Job.where(finished_at: nil)
    due_by = ->(time) { unfinished.where('COALESCE(scheduled_at, created_at) <= ?', time) }
    stale = due_by.call(Time.now - args[:max_age].to_i).count

    raise "#{stale} jobs older than #{args[:max_age]} seconds have not been processed yet" if stale.positive?

    puts "OK - no job has been waiting longer than #{args[:max_age]} seconds " \
         "(#{unfinished.count} unfinished job(s), of which #{due_by.call(Time.now).count} due)"
  end
end
