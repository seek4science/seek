class AddSimulationFlagToDataFile < ActiveRecord::Migration
  def change
    add_column :data_files, :simulation_data, :boolean, default:false
    add_column :data_file_versions, :simulation_data, :boolean, default:false
  end
end
