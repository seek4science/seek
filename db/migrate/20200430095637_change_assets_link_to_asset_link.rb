class ChangeAssetsLinkToAssetLink < ActiveRecord::Migration[5.2]
  def change
    rename_table :assets_links, :asset_links
  end
end
