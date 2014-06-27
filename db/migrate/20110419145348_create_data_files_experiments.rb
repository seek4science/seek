class CreateDataFilesExperiments < ActiveRecord::Migration
  def self.up
    create_table :data_files_experiments, :id => false do |t|
      t.integer :data_file_id
      t.integer :experiment_id
    end
  end

  def self.down
    drop_table :data_files_experiments
  end
end
