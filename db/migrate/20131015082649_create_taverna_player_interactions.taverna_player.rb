# This migration comes from taverna_player (originally 20130714140911)
class CreateTavernaPlayerInteractions < ActiveRecord::Migration
  def change
    create_table :taverna_player_interactions do |t|
      t.string :uri
      t.boolean :replied, :default => false
      t.references :run

      t.timestamps
    end

    add_index :taverna_player_interactions, :run_id
  end
end
