class TaskJob < ApplicationJob
  before_enqueue do
    task.update_attribute(:status, Task::STATUS_QUEUED)
  end

  before_perform do
    task.update_attribute(:status, Task::STATUS_ACTIVE)
  end

  after_perform do
    task.update_attribute(:status, Task::STATUS_DONE)
  end

  rescue_from(StandardError) do |exception|
    task.update_attribute(:status, Task::STATUS_FAILED)
  end

  def task
    raise 'implement me'
  end
end
