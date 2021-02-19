class WorkflowStatus < ApplicationRecord
  STATUSES = ["all_passing", "some_passing", "all_failing", "not_available"]
  belongs_to :workflow
  has_one :workflow_version, ->(s) { where(version: s.version) }, through: :workflow, source: :versions

  validates :status, inclusion: { in: STATUSES }
end