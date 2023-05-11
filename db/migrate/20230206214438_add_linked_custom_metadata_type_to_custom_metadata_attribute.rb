class AddLinkedCustomMetadataTypeToCustomMetadataAttribute < ActiveRecord::Migration[6.1]
  def change
    add_column :custom_metadata_attributes,:linked_custom_metadata_type_id,:integer
  end
end
