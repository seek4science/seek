class AddFactorsStudiedFieldToMeasuredItemsTable < ActiveRecord::Migration
  def self.up
    add_column :measured_items, :factors_studied, :boolean, :default => true
  end

  def self.down
    remove_column :measured_items, :factors_studied
  end
end
