class CreateCustomMetadataAttribute < ActiveRecord::Migration[5.2]
  def up
    # see https://github.com/seek4science/seek/issues/474
    if (table_exists? :custom_metadata_attributes)
      drop_table :custom_metadata_attributes
    end

    create_table :custom_metadata_attributes do |t|
      t.references :custom_metadata_type
      t.references :sample_attribute_type
      t.boolean :required, default: false
      t.integer :pos
      t.string :title
    end
  end

  def down
    drop_table :custom_metadata_attributes
  end
end
