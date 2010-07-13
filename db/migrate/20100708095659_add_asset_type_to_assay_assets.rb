class AddAssetTypeToAssayAssets < ActiveRecord::Migration
  def self.up
    add_column :assay_assets, :asset_type, :string
  end

  def self.down
    remove_column :assay_assets, :asset_type
  end
end
