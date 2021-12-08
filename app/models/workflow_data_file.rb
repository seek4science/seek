class WorkflowDataFile < ApplicationRecord
  belongs_to :workflow
  belongs_to :data_file
end
