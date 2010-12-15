class AddKeyToAssayClass < ActiveRecord::Migration
  def self.up
    add_column :assay_classes, :key, :string, :limit=>10
  end

  def self.down
    remove_column :assay_classes,:key
  end
end
