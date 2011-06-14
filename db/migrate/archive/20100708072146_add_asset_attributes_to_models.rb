class AddAssetAttributesToModels < ActiveRecord::Migration
  def self.up
    add_column :models, :project_id, :integer 
    add_column :models, :policy_id, :integer    
  end

  def self.down
    remove_column :models, :project_id
    remove_column :models, :policy_id
  end
end
