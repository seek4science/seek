class AddIsPalFlagToPerson < ActiveRecord::Migration
  def self.up
    add_column :people, :is_pal, :boolean, :default=>false
  end

  def self.down
    remove_column :people, :is_pal
  end
end
