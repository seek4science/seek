class AddAssetAttributesToModelVersions < ActiveRecord::Migration
  def self.up
    add_column :model_versions, :project_id, :integer 
    add_column :model_versions, :policy_id, :integer    
  end

  def self.down
    remove_column :model_versions, :project_id
    remove_column :model_versions, :policy_id
  end
end
