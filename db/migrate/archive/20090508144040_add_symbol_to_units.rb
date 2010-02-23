class AddSymbolToUnits < ActiveRecord::Migration
  def self.up
    add_column :units, :symbol,:string
    add_column :units, :comment,:string
  end

  def self.down
    remove_column :units,:symbol
    remove_column :units,:comment
  end
end
