class AddRolesMaskToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :roles_mask, :integer
  end

  def self.down
    remove_column :people, :roles_mask
  end
end
