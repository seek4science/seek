class AddLabelToCustomMetadataAttribute < ActiveRecord::Migration[5.2]
  def change
    add_column :custom_metadata_attributes, :label, :string
  end
end
