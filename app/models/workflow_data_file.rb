class WorkflowDataFile < ApplicationRecord
  belongs_to :workflow, inverse_of: :workflow_data_files
  belongs_to :data_file, inverse_of: :workflow_data_files

  belongs_to :workflow_data_file_relationship

  validates :workflow, :data_file, presence: true
end
