class AddWorkflowClassIdToWorkflows < ActiveRecord::Migration[5.2]
  def change
    add_column :workflows, :workflow_class_id, :integer
  end
end
