class Task < ApplicationRecord
  STATUS_WAITING = 'waiting'.freeze
  STATUS_QUEUED = 'queued'.freeze
  STATUS_ACTIVE = 'active'.freeze
  STATUS_DONE = 'done'.freeze
  STATUS_FAILED = 'failed'.freeze
  belongs_to :resource, polymorphic: true, inverse_of: :tasks
  before_validation :initialize_status
  validates :status, inclusion: { in: [STATUS_WAITING, STATUS_QUEUED, STATUS_ACTIVE, STATUS_DONE, STATUS_FAILED] }

  def completed?
    status == STATUS_DONE || status == STATUS_FAILED
  end

  def pending?
    status.nil? || status == STATUS_WAITING || status == STATUS_QUEUED
  end

  private

  def initialize_status
    self.status ||= STATUS_WAITING
  end
end

