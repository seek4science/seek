class ApplicationJob < ActiveJob::Base
  include CommonSweepers

  # the name of the queue the job will be places on - so that multiple workers can watch different queues.
  queue_as QueueNames::DEFAULT
  queue_with_priority  2

  # time limit for the whole job to run, after which a timeout exception will be raised
  def timelimit
    15.minutes
  end

  # time before the job is run
  def default_delay
    3.seconds
  end

  # whether a new job will be created once this one finishes.
  # for example, sending weekly emails once finished creates a new job to start in 1 week
  def follow_on_job?
    false
  end

  # the priority of the follow on job
  def follow_on_priority
    default_priority
  end

  def default_priority
    self.class.default_priority
  end

  # the delay for the follow on job, which defaults to the default delay but could be different
  def follow_on_delay
    1.second
  end

  after_perform do |job|
    if job.follow_on_job?
      job.queue_job(follow_on_priority, follow_on_delay.from_now)
    end
  end

  # adds the job to the Delayed Job queue. Will not create it if it already exists and allow_duplicate is false,
  # or by default allow_duplicate_jobs? returns false.
  def queue_job(priority = nil, time = default_delay.from_now)
    args = { wait_until: time }
    args[:priority] = priority if priority

    enqueue(args)
  end
end