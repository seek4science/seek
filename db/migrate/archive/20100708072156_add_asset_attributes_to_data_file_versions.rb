class AddAssetAttributesToDataFileVersions < ActiveRecord::Migration
  def self.up
    add_column :data_file_versions, :project_id, :integer 
    add_column :data_file_versions, :policy_id, :integer    
  end

  def self.down
    remove_column :data_file_versions, :project_id
    remove_column :data_file_versions, :policy_id
  end
end
