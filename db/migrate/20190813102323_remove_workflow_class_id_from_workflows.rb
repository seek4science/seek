class RemoveWorkflowClassIdFromWorkflows < ActiveRecord::Migration[5.2]
  def change
    remove_column :workflows, :workflow_class_id, :integer
  end
end
