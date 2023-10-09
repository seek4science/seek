class RenameCustomMetadataToExtendedMetadata < ActiveRecord::Migration[6.1]
  def change

    rename_table :custom_metadata, :extended_metadata
    rename_column :extended_metadata, :custom_metadata_type_id, :extended_metadata_type_id
    rename_column :extended_metadata, :custom_metadata_attribute_id, :extended_metadata_attribute_id
  end
end
