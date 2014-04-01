class AddSweepableFlagToWorkflowVersions < ActiveRecord::Migration
  def change
    add_column :workflow_versions, :sweepable, :boolean
  end
end
