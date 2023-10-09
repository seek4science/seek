class RenameCustomMetadataTypesToExtendedMetadataTypes < ActiveRecord::Migration[6.1]
  def change
    rename_table :custom_metadata_types, :extended_metadata_types
  end
end
