class AddWorkflowVersionToTavernaPlayerRuns < ActiveRecord::Migration
  def change
    change_table :taverna_player_runs do |t|
      t.integer :workflow_version, :default => 1
    end
  end
end
