class AddUserAssetIdIndexToAssayAuthlookup < ActiveRecord::Migration
  def self.up
    add_index :assay_auth_lookup, [:user_id,:asset_id]
  end

  def self.down
    remove_index :assay_auth_lookup, [:user_id,:asset_id]
  end
end
