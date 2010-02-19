class AddDummyFieldToPerson < ActiveRecord::Migration
  def self.up
    add_column :people, :is_dummy, :boolean, :default=>false
  end

  def self.down
    remove_column :people, :is_dummy
  end
end
