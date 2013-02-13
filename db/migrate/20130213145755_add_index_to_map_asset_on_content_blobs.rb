class AddIndexToMapAssetOnContentBlobs < ActiveRecord::Migration
  def self.up
    add_index :content_blobs,[:asset_id,:asset_type]
  end

  def self.down
    remove_index :content_blobs,[:asset_id,:asset_type]
  end
end
