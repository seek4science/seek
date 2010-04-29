class AddOtherCreatorsToDataFiles < ActiveRecord::Migration
  def self.up
    add_column :data_files, :other_creators, :text
    add_column :data_file_versions, :other_creators, :text
  end

  def self.down
    remove_column :data_files, :other_creators
    remove_column :data_file_versions, :other_creators
  end
end
