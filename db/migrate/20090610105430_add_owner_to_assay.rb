class AddOwnerToAssay < ActiveRecord::Migration
  def self.up
    add_column :assays, :owner_id, :integer
  end

  def self.down
    remove_column :assays, :owner_id
  end
end
