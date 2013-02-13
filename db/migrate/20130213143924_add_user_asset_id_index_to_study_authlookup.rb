class AddUserAssetIdIndexToStudyAuthlookup < ActiveRecord::Migration
  def self.up
    add_index :study_auth_lookup, [:user_id,:asset_id]
  end

  def self.down
    remove_index :study_auth_lookup, [:user_id,:asset_id]
  end
end
