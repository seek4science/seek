class AddMonitoredToWorkflowVersions < ActiveRecord::Migration[5.2]
  def change
    add_column :workflow_versions, :monitored, :boolean
  end
end
