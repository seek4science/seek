class AddDescriptionToCustomMetadataAttribute < ActiveRecord::Migration[5.2]
  def change
    add_column :custom_metadata_attributes, :description, :text
  end
end
