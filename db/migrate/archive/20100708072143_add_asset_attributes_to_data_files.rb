class AddAssetAttributesToDataFiles < ActiveRecord::Migration
  def self.up
    add_column :data_files, :project_id, :integer 
    add_column :data_files, :policy_id, :integer    
  end

  def self.down
    remove_column :data_files, :project_id
    remove_column :data_files, :policy_id
  end
end
