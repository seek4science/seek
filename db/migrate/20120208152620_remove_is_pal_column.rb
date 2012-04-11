class RemoveIsPalColumn < ActiveRecord::Migration
  def self.up
    remove_column :people, :is_pal
  end

  def self.down
    add_column :people, :is_pal, :boolean, :default => false
  end
end
