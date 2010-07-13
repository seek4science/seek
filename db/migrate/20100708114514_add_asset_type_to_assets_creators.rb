class AddAssetTypeToAssetsCreators < ActiveRecord::Migration
  def self.up
    add_column :assets_creators, :asset_type, :string
  end

  def self.down
    remove_column :assets_creators, :asset_type
  end
end
