class ChangeAssetAuthorsToCreators < ActiveRecord::Migration
  def self.up
    rename_table(:asset_authors, :assets_creators)
  end

  def self.down
    rename_table(:assets_creators, :asset_authors)
  end
end
