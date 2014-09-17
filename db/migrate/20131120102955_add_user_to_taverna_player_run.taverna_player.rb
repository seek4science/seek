# This migration comes from taverna_player (originally 20131112165520)
class AddUserToTavernaPlayerRun < ActiveRecord::Migration
  def change
    add_column :taverna_player_runs, :user_id, :integer
  end
end
