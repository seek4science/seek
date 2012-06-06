class AddIsWithSampleToDataFiles < ActiveRecord::Migration
  def self.up
    add_column :data_files, :is_with_sample, :boolean
    add_column :data_file_versions, :is_with_sample, :boolean
  end

  def self.down
    remove_column :data_files, :is_with_sample
    remove_column :data_file_versions, :is_with_sample
  end
end
