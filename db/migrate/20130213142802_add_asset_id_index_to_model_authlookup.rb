class AddAssetIdIndexToModelAuthlookup < ActiveRecord::Migration
  def self.up
    add_index :model_auth_lookup, [:user_id,:asset_id]
  end

  def self.down
    remove_index :model_auth_lookup, [:user_id,:asset_id]
  end
end
