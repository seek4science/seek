class ChangeAssetLinkUrlToText < ActiveRecord::Migration[5.2]
  def up
    change_column :asset_links, :url, :text
  end

  def down
    change_column :asset_links, :url, :string
  end
end
