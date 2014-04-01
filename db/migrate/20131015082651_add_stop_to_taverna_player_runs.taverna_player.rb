# This migration comes from taverna_player (originally 20130717155415)
class AddStopToTavernaPlayerRuns < ActiveRecord::Migration
  def change
    add_column :taverna_player_runs, :stop, :boolean, :default => false
  end
end
