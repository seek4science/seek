class AddWorkflowClassRefToWorkflowVersions < ActiveRecord::Migration[5.2]
  def change
    add_column :workflow_versions, :workflow_class_id, :integer
  end
end
