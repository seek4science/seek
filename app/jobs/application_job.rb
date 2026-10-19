class ApplicationJob < ActiveJob::Base
  # the name of the queue the job will be places on - so that multiple workers can watch different queues.
  queue_as QueueNames::DEFAULT
  queue_with_priority  2

  rescue_from(Exception) do |exception|
    unless exception.is_a?(ActiveJob::DeserializationError) &&
           exception.cause.is_a?(ActiveRecord::RecordNotFound)
      raise exception if Rails.env.test?
      report_exception(exception)
    end
  end

  # time limit for the whole job to run, after which a timeout exception will be raised
  def timelimit
    15.minutes
  end

  # time before the job is run
  def default_delay
    0.seconds
  end

  # whether a new job will be created once this one finishes.
  # for example, sending weekly emails once finished creates a new job to start in 1 week
  def follow_on_job?
    false
  end

  def default_priority
    self.class.default_priority
  end

  # the delay for the follow on job, which defaults to the default delay but could be different
  def follow_on_delay
    default_delay
  end

  around_perform do |job, block|
    Timeout.timeout(job.timelimit) do
      block.call
    end
  end

  after_perform do |job|
    job.queue_follow_on_job if job.follow_on_job?
  end

  # Enqueues the next job in a follow-on chain, as a new job rather than a re-enqueue of this one.
  # ActiveJob#enqueue keeps the existing job_id, and the jobs dashboard looks jobs up by ActiveJob
  # id, so sharing an id across a chain makes every job in it resolve to the last one.
  def queue_follow_on_job
    options = {}
    options[:wait] = follow_on_delay if follow_on_delay

    self.class.set(**options).perform_later(*arguments)
  end

  # adds the job to the queue.
  def queue_job(priority = nil, delay = default_delay)
    args = { }
    args[:wait] = delay if delay
    args[:priority] = priority if priority

    enqueue(args)
  end

  def report_exception(exception, message = nil, data = {})
    data.merge!({job_class: self.class.name, arguments: arguments.inspect})
    message ||= "Error executing job for #{self.class.name}"
    Seek::Errors::ExceptionForwarder.send_notification(exception, data: data)
    Rails.logger.error(message)
    Rails.logger.error(exception)
  end

  # A single point of entry to queue various jobs that depend on some period of time elapsing before they are run, without
  # far-future scheduling (reasoning: https://lanceolsen.net/never-schedule-future-jobs/).
  #
  # Using a single method is faster than having individual entries for each type of job in `schedule.rb`, since it would
  # have to initialise a SEEK instance for each.
  def self.queue_timed_jobs
    OpenbisEndpointCacheRefreshJob.queue_timed_jobs
    OpenbisSyncJob.queue_timed_jobs
    ProjectLeavingJob.queue_timed_jobs
  end
end