class ApplicationJob < ActiveJob::Base
  include CommonSweepers

  # the name of the queue the job will be places on - so that multiple workers can watch different queues.
  queue_as QueueNames::DEFAULT
end