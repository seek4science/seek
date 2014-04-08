# This migration comes from taverna_player (originally 20130320102600)
class AddStatusMessageToTavernaPlayerRuns < ActiveRecord::Migration
  def change
    add_column :taverna_player_runs, :status_message, :string
  end
end
