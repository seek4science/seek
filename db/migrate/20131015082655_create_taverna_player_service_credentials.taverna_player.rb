# This migration comes from taverna_player (originally 20130918135348)
class CreateTavernaPlayerServiceCredentials < ActiveRecord::Migration
  def change
    create_table :taverna_player_service_credentials do |t|
      t.string :uri, :null => false
      t.string :name
      t.text :description
      t.string :login
      t.string :password

      t.timestamps
    end

    add_index :taverna_player_service_credentials, :uri
  end
end
