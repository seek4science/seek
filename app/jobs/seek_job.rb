# top level abstract class for defining jobs
# that automatically handles performing the job, and and handling and reporting any errors.
# utility methods for counting and checking if a job exists, and creating a new job.
class SeekJob < ApplicationJob
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
        end
      end
    end
  end

  private

  def gather_items
    []
  end

  def report_exception(exception, item, message = nil, data = {})
    message ||= "Error executing job for #{self.class.name}"
    data[:message] = message
    data[:item] = item.inspect
    Seek::Errors::ExceptionForwarder.send_notification(exception, data:data)
    Rails.logger.error(message)
    Rails.logger.error(exception)
  end
end
