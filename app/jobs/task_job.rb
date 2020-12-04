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
    task.update_attribute(:status, Task::STATUS_FAILED)
  end

  def task
    raise 'implement me'
  end
end
