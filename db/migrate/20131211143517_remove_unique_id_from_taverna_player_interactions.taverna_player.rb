# This migration comes from taverna_player (originally 20131126175424)
class RemoveUniqueIdFromTavernaPlayerInteractions < ActiveRecord::Migration
  def up
    remove_index :taverna_player_interactions, :unique_id
    remove_column :taverna_player_interactions, :unique_id
  end

  def down
    add_column :taverna_player_interactions, :unique_id, :string
    add_index :taverna_player_interactions, :unique_id
  end
end
