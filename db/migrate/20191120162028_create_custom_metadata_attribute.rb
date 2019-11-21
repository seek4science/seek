class CreateCustomMetadataAttribute < ActiveRecord::Migration[5.2]
  def change
    create_table :custom_metadata_attributes do |t|
      t.references :custom_metadata
      t.references :sample_attribute_type
      t.boolean "required", default: false
      t.integer "pos"
      t.string :title
    end
  end
end
