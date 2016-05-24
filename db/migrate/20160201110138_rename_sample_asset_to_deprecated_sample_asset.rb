class RenameSampleAssetToDeprecatedSampleAsset < ActiveRecord::Migration

  def change
    rename_table :sample_assets, :deprecated_sample_assets
  end

end
