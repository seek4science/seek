class AddExtendedMetadataAttributePropertyId < ActiveRecord::Migration[6.1]
  def change
    add_column :extended_metadata_attributes, :property_type_id, :string
  end
end
