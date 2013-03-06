class AddIndexForAssetCreatorJoinTable < ActiveRecord::Migration
  def self.up
    add_index :assets_creators,[:asset_id, :asset_type]
  end

  def self.down
    remove_index :assets_creators,[:asset_id, :asset_type]
  end
end
