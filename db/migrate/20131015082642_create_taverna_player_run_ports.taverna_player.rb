# This migration comes from taverna_player (originally 20130315163019)
class CreateTavernaPlayerRunPorts < ActiveRecord::Migration
  def change
    create_table :taverna_player_run_ports do |t|
      t.string :name
      t.string :value
      t.string :file
      t.string :port_type
      t.references :run

      t.timestamps
    end

    add_index :taverna_player_run_ports, :run_id
  end
end
