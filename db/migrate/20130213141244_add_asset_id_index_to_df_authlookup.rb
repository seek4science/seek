class AddAssetIdIndexToDfAuthlookup < ActiveRecord::Migration
  def self.up
    add_index :data_file_auth_lookup, [:user_id,:asset_id, :can_view]
  end

  def self.down
    remove_index :data_file_auth_lookup, [:user_id,:asset_id, :can_view]
  end
end
