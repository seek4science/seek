# This migration comes from taverna_player (originally 20131102113933)
class AddPageUriToTavernaPlayerInteraction < ActiveRecord::Migration
  def change
    add_column :taverna_player_interactions, :page_uri, :string
  end
end
