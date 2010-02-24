class AddRelationshipTypeIdToAssayAssets < ActiveRecord::Migration
  def self.up
    add_column :assay_assets, :relationship_type_id, :integer  
  end

  def self.down
    remove_column :assay_assets, :relationship_type_id
  end
end
