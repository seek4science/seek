# This migration comes from taverna_player (originally 20130313105546)
class CreateTavernaPlayerRuns < ActiveRecord::Migration
  def change
    create_table :taverna_player_runs do |t|
      t.string :run_id
      t.string :state, :default => "pending", :null => false
      t.datetime :create_time
      t.datetime :start_time
      t.datetime :finish_time
      t.integer :workflow_id, :null => false

      t.timestamps
    end

    add_index :taverna_player_runs, :run_id
  end
end
