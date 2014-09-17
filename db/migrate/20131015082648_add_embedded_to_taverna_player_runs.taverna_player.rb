# This migration comes from taverna_player (originally 20130705142704)
class AddEmbeddedToTavernaPlayerRuns < ActiveRecord::Migration
  def change
    add_column :taverna_player_runs, :embedded, :boolean, :default => false
  end
end
