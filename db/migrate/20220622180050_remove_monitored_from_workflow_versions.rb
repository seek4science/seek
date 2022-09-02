class RemoveMonitoredFromWorkflowVersions < ActiveRecord::Migration[6.1]
  def change
    remove_column :workflow_versions, :monitored, :boolean
  end
end
