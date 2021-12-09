class WorkflowDataFile < ApplicationRecord
  belongs_to :workflow
  belongs_to :data_file

  belongs_to :workflow_data_file_relationship

  validates :workflow, :data_file, presence: true
end
