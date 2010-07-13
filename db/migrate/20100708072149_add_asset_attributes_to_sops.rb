class AddAssetAttributesToSops < ActiveRecord::Migration
  def self.up
    add_column :sops, :project_id, :integer 
    add_column :sops, :policy_id, :integer    
  end

  def self.down
    remove_column :sops, :project_id
    remove_column :sops, :policy_id
  end
end
