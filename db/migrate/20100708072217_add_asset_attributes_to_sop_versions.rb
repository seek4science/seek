class AddAssetAttributesToSopVersions < ActiveRecord::Migration
  def self.up
    add_column :sop_versions, :project_id, :integer 
    add_column :sop_versions, :policy_id, :integer    
  end

  def self.down
    remove_column :sop_versions, :project_id
    remove_column :sop_versions, :policy_id
  end
end
