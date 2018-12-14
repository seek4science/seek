class RemoveExternalAssetsByExternalIdIndex < ActiveRecord::Migration
  def change
    #due to needing to edit an old (but unreleased) migration. This migration is to clean up for those that had run it
    if index_exists?(:external_assets, %i[external_id external_service], unique: true, name: 'external_assets_by_external_id')
      remove_index :external_assets, name: 'external_assets_by_external_id'
    end
  end
end
