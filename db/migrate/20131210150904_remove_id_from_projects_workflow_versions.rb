class RemoveIdFromProjectsWorkflowVersions < ActiveRecord::Migration
  def up
    remove_column :projects_workflow_versions, :id
  end

  def down
    add_column :projects_workflow_versions, :id, :primary_key
  end
end
