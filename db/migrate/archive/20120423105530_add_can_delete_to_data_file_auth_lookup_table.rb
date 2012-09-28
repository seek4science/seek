class AddCanDeleteToDataFileAuthLookupTable < ActiveRecord::Migration
  def self.up
    add_column :data_file_auth_lookup, :can_delete, :boolean, :default=>false
  end

  def self.down
    remove_column :data_file_auth_lookup, :can_delete
  end
end
