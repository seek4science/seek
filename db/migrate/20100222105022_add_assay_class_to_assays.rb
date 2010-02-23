class AddAssayClassToAssays < ActiveRecord::Migration
  def self.up
    add_column :assays, :assay_class_id, :integer  
  end

  def self.down
    remove_column :assays, :assay_class_id
  end
end
