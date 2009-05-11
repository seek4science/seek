class RemoveParentAssayFromAssay < ActiveRecord::Migration
  def self.up
    remove_column(:assays, :parent_assay_id)
  end

  def self.down
    add_column(:assays,:parent_assay_id,:integer)
  end
end
