class RemoveExperimentFromDataFile < ActiveRecord::Migration
  def self.up
    remove_column(:data_files, :experiment_id)
  end

  def self.down
    add_column :data_files, :experiment_id, :integer
  end
end
