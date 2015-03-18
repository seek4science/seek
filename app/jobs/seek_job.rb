#top level abstract class for defining jobs
#that automatically handles performing the job, and and handling and reporting any errors.
#utility methods for counting and checking if a job exists, and creating a new job.
class SeekJob
  include CommonSweepers

  def perform

      gather_items.each do |item|
        begin
          Timeout::timeout(timelimit) do
            perform_job(item)
          end
        rescue Exception=>exception
          report_exception(exception)
          retry_item(item)
        end
      end
      if follow_on_job?
        create_job(follow_on_priority,follow_on_delay.from_now)
      end
  end

  def create_job priority=default_priority,time=default_delay.from_now
    Delayed::Job.enqueue(self, :priority=>priority, :queue=>queue_name,:run_at=>time)
  end

  def exists?
    count!=0
  end

  def count ignore_locked=true
    if ignore_locked
      Delayed::Job.where(['handler = ? AND locked_at IS ? AND failed_at IS ?',job_yaml,nil,nil]).count
    else
      Delayed::Job.where(['handler = ? AND failed_at IS ?',job_yaml,nil]).count
    end
  end

  private

  def timelimit
    15.minutes
  end

  def job_yaml
    self.class.new.to_yaml
  end

  def default_priority
    2
  end

  def default_delay
    10.minutes
  end

  def follow_on_job?
    false
  end

  def follow_on_priority
    default_priority
  end

  def follow_on_delay
    1.second
  end

  def queue_name
    nil
  end

  def gather_items
    []
  end

  def retry_item item
    #by default doesn't retry
  end

  def report_exception exception,message=nil,data={}
    message||= "Error executing job for #{self.class.name}"
    data[:message]=message
    if Seek::Config.exception_notification_enabled
      ExceptionNotifier.notify_exception(exception,:data=>data)
    end
    Rails.logger.error(exception)
  end

  def take_queued_item(queued)
    item = queued.item
    queued.destroy
    item
  end

end