class AddOrderFieldToUnitsTable < ActiveRecord::Migration
  def self.up
    add_column :units, :order, :integer
  end

  def self.down
    remove_column :units, :order
  end
end
