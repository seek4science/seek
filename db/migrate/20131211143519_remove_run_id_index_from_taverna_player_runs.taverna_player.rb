# This migration comes from taverna_player (originally 20131127163438)
class RemoveRunIdIndexFromTavernaPlayerRuns < ActiveRecord::Migration
  def up
    remove_index :taverna_player_runs, :run_id
  end

  def down
    add_index :taverna_player_runs, :run_id
  end
end
