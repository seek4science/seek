class AddIsDummyToSpecimens < ActiveRecord::Migration
  def self.up
    add_column :specimens, :is_dummy, :boolean, :default => false
  end

  def self.down
    remove_column :specimens, :is_dummy
  end
end
