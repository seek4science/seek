# top level abstract class for defining jobs
# that automatically handles performing the job, and and handling and reporting any errors.
# utility methods for counting and checking if a job exists, and creating a new job.
class SeekJob < ApplicationJob
  include DefaultJobProperties # the default properties - these are methods that can be overridden in the job implementation

  def perform
    gather_items.each do |item|
      begin
        Timeout.timeout(timelimit) do
          perform_job(item)
        end
      rescue Exception => exception
        raise exception if Rails.env.test?
        unless item.respond_to?(:destroyed?) && item.destroyed?
          report_exception(exception, item)
          retry_item(item)
        end
      end
    end
    if follow_on_job?
      queue_job(follow_on_priority, follow_on_delay.from_now, true)
    end
  end

  # adds the job to the Delayed Job queue. Will not create it if it already exists and allow_duplicate is false,
  # or by default allow_duplicate_jobs? returns false.
  def queue_job(priority = nil, time = default_delay.from_now)
    args = { run_at: time }
    args[:priority] = priority if priority

    enqueue(args)
  end

  private

  def gather_items
    []
  end

  def retry_item(_item)
    # by default doesn't retry
  end

  def report_exception(exception, item, message = nil, data = {})
    message ||= "Error executing job for #{self.class.name}"
    data[:message] = message
    data[:item] = item.inspect
    Seek::Errors::ExceptionForwarder.send_notification(exception, data:data)
    Rails.logger.error(message)
    Rails.logger.error(exception)
  end

  def take_queued_item(queued)
    item = queued.item
    queued.destroy
    item
  end
end
