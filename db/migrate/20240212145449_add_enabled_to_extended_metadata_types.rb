class AddEnabledToExtendedMetadataTypes < ActiveRecord::Migration[6.1]
  def change
    add_column :extended_metadata_types, :enabled, :boolean, default: true
  end
end
