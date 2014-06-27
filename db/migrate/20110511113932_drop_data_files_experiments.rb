class DropDataFilesExperiments < ActiveRecord::Migration
  def self.up
    drop_table :data_files_experiments
  end

  def self.down
     create_table :data_files_experiments, :id => false do |t|
      t.integer :data_file_id
      t.integer :experiment_id
    end
  end
end
