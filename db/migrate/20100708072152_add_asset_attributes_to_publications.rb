class AddAssetAttributesToPublications < ActiveRecord::Migration
  def self.up
    add_column :publications, :project_id, :integer 
    add_column :publications, :policy_id, :integer    
  end

  def self.down
    remove_column :publications, :project_id
    remove_column :publications, :policy_id
  end
end
