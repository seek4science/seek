class AddDataFileAndVersionToTavernaPlayerRunPorts < ActiveRecord::Migration
  def change
    add_column :taverna_player_run_ports,:data_file_id,:integer
    add_column :taverna_player_run_ports,:data_file_version,:integer
  end
end
