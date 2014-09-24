class AddReportedToTavernaPlayerRuns < ActiveRecord::Migration
  def change
    add_column :taverna_player_runs, :reported, :boolean, :default => false
  end
end
