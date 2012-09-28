class RemoveIsAdminColumn < ActiveRecord::Migration
  def self.up
    remove_column :people, :is_admin
  end

  def self.down
    add_column :people, :is_admin, :boolean, :default => false
  end
end
