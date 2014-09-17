# This migration comes from taverna_player (originally 20131127162157)
class AddIndexesWhereMissing < ActiveRecord::Migration
  def change
    add_index :taverna_player_interactions, [:run_id, :serial]
    add_index :taverna_player_interactions, [:run_id, :replied]

    add_index :taverna_player_run_ports, [:run_id, :name]

    add_index :taverna_player_runs, :user_id
    add_index :taverna_player_runs, :workflow_id
    add_index :taverna_player_runs, :parent_id
  end
end
