class AddUserAssetIdIndexToPublicationAuthlookup < ActiveRecord::Migration
  def self.up
    add_index :publication_auth_lookup, [:user_id,:asset_id]
  end

  def self.down
    remove_index :publication_auth_lookup, [:user_id,:asset_id]
  end
end
