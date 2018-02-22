class QueueNames
  SAMPLES='samples'
  REMOTE_CONTENT='remotecontent'
  AUTH_LOOKUP='authlookup'
  DEFAULT=Delayed::Worker.default_queue_name
  MAILERS=ActionMailer::DeliveryJob.queue_name
end