class AddCustomMetadataAttributeToCustomMetadata < ActiveRecord::Migration[6.1]
  def change
    add_column :custom_metadata, :custom_metadata_attribute_id,:integer
  end
end
