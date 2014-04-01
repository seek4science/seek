# This migration comes from taverna_player (originally 20131018160715)
class AddParentRunIdToTavernaPlayerRuns < ActiveRecord::Migration
  def change
    add_column :taverna_player_runs, :parent_id, :integer
  end
end
