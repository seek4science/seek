class RenameExtendedMetadataAttributePropertyTypeId < ActiveRecord::Migration[6.1]
  def change
    rename_column :extended_metadata_attributes, :property_type_id, :pid
  end
end
