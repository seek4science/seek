class AddFactorsStudiedFieldToUnitsTable < ActiveRecord::Migration
  def self.up
    add_column :units, :factors_studied, :boolean, :default => true
  end

  def self.down
    remove_column :units, :factors_studied
  end
end
