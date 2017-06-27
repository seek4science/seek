module DefaultJobProperties
  # whether create_job will create a new job if one already exists with the same properties
  def allow_duplicate_jobs?
    true
  end

  # time limit for the whole job to run, after which a timeout exception will be raised
  def timelimit
    15.minutes
  end

  # the priority of the job on the queue
  def default_priority
    2
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

  # the delay for the follow on job, which defaults to the default delay but could be different
  def follow_on_delay
    1.second
  end

  # the name of the queue the job will be places on - so that multiple workers can watch different queues.
  def queue_name
    QueueNames::DEFAULT
  end
end
