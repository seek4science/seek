# This migration comes from taverna_player (originally 20131010094537)
class AddReplyCachingToTavernaPlayerInteractions < ActiveRecord::Migration
  def up
    remove_column :taverna_player_interactions, :uri
    add_column :taverna_player_interactions, :unique_id, :string
    add_column :taverna_player_interactions, :page, :text
    add_column :taverna_player_interactions, :feed_reply, :string
    add_column :taverna_player_interactions, :output_value, :text, :limit => 16777215
    add_index :taverna_player_interactions, :unique_id
  end

  def down
    remove_index :taverna_player_interactions, :unique_id
    remove_column :taverna_player_interactions, :output_value
    remove_column :taverna_player_interactions, :feed_reply
    remove_column :taverna_player_interactions, :page
    remove_column :taverna_player_interactions, :unique_id
    add_column :taverna_player_interactions, :uri, :string
  end
end
