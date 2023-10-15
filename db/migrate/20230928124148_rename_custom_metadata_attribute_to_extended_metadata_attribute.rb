class RenameCustomMetadataAttributeToExtendedMetadataAttribute < ActiveRecord::Migration[6.1]
    def change
      rename_table :custom_metadata_attributes, :extended_metadata_attributes

      rename_column :extended_metadata_attributes, :custom_metadata_type_id, :extended_metadata_type_id
      rename_column :extended_metadata_attributes, :linked_custom_metadata_type_id, :linked_extended_metadata_type_id
    end
end
