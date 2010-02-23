class RemoveParentTypeIdFromAssayType < ActiveRecord::Migration
  
  def self.up
    remove_column(:assay_types, :parent_assay_type_id)
  end

  def self.down
    add_column :assay_types, :parent_assay_type_id, :string
  end

end
