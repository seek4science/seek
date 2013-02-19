class AddUserAssetIdIndexToEventAuthlookup < ActiveRecord::Migration
  def self.up
    add_index :event_auth_lookup, [:user_id,:asset_id, :can_view]
  end

  def self.down
    remove_index :event_auth_lookup, [:user_id,:asset_id, :can_view]
  end
end
