class WorkflowDataFileRelationship < ApplicationRecord
  validates :title, :key,  presence: true, uniqueness: true
end
