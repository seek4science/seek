class RemoveIsWithSampleFromDataFiles < ActiveRecord::Migration
  def self.up
    remove_column :data_files, :is_with_sample
    remove_column :data_file_versions, :is_with_sample
  end

  def self.down
    add_column :data_files, :is_with_sample, :boolean
    add_column :data_file_versions, :is_with_sample, :boolean
  end
end
