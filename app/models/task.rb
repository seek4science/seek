class Task < ApplicationRecord
  STATUS_WAITING = 'waiting'.freeze
  STATUS_QUEUED = 'queued'.freeze
  STATUS_ACTIVE = 'active'.freeze
  STATUS_DONE = 'done'.freeze
  STATUS_FAILED = 'failed'.freeze
  STATUS_CANCELLED = 'cancelled'.freeze
  belongs_to :resource, polymorphic: true, inverse_of: :tasks

  def completed?
    [STATUS_DONE, STATUS_FAILED].include?(status)
  end

  def pending?
    [STATUS_WAITING, STATUS_QUEUED].include?(status)
  end

  def in_progress?
    Task.status_in_progress?(status)
  end

  def cancelled?
    status == STATUS_CANCELLED
  end

  def success?
    status == STATUS_DONE
  end

  def failed?
    status == STATUS_FAILED
  end

  def waiting?
    status == STATUS_WAITING
  end

  def start
    return if persisted? && (pending? || in_progress?)

    update_attribute(:status, Task::STATUS_WAITING)
    yield if block_given?
  end

  def cancel
    update_attribute(:status, Task::STATUS_CANCELLED)
  end

  def self.status_in_progress?(current_status)
    [STATUS_QUEUED, STATUS_ACTIVE].include?(current_status)
  end
end
