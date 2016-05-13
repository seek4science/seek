class UpdateSamplesAndSpecimenInAssetCreators < ActiveRecord::Migration
  def up
    execute("UPDATE assets_creators SET asset_type='DeprecatedSpecimen' WHERE asset_type='Specimen';")
    execute("UPDATE assets_creators SET asset_type='DeprecatedSample' WHERE asset_type='Sample';")
  end

  def down
    execute("UPDATE assets_creators SET asset_type='Specimen' WHERE asset_type='DeprecatedSpecimen';")
    execute("UPDATE assets_creators SET asset_type='Sample' WHERE asset_type='DeprecatedSample';")
  end
end
