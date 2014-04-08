# This migration comes from taverna_player (originally 20130812155839)
class AddNameToTavernaPlayerRuns < ActiveRecord::Migration
  def change
    add_column :taverna_player_runs, :name, :string, :default => "None"
  end
end
