class TaskJob < ApplicationJob
  before_enqueue do
    task.start
    task.update_attribute(:status, Task::STATUS_QUEUED)
  end

  around_perform do |job, block|
    unless task.cancelled?
      task.update_attribute(:status, Task::STATUS_ACTIVE)
      block.call
      task.update_attribute(:status, Task::STATUS_DONE)
    end
  end

  rescue_from(StandardError) do |exception|
    handle_error(exception)
  end

  def task
    raise 'implement me'
  end

  def handle_error(exception)
    task.update_attribute(:status, Task::STATUS_FAILED)
    task.update_attribute(:exception, exception.full_message)
    task.update_attribute(:error_message, "#{exception.class.name}: #{exception.message}")
    report_exception(exception, "Error occurred with a Task for Job: #{self.class.name}")
  end
end
