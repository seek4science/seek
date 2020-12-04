class Task < ApplicationRecord
  STATUS_WAITING = 'waiting'.freeze
  STATUS_QUEUED = 'queued'.freeze
  STATUS_ACTIVE = 'active'.freeze
  STATUS_DONE = 'done'.freeze
  STATUS_FAILED = 'failed'.freeze
  STATUS_CANCELLED = 'cancelled'.freeze
  belongs_to :resource, polymorphic: true, inverse_of: :tasks

  def completed?
    status == STATUS_DONE || status == STATUS_FAILED
  end

  def pending?
    status == STATUS_WAITING || status == STATUS_QUEUED
  end

  def in_progress?
    status == STATUS_QUEUED || status == STATUS_ACTIVE
  end

  def cancelled?
    status == STATUS_CANCELLED
  end

  def start
    return if persisted? && (pending? || in_progress?)
    update_attribute(:status, Task::STATUS_WAITING)
    yield if block_given?
  end

  def cancel
    update_attribute(:status, Task::STATUS_CANCELLED)
  end
end

