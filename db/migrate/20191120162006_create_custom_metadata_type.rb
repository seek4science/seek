class CreateCustomMetadataType < ActiveRecord::Migration[5.2]
  def up
    # see https://github.com/seek4science/seek/issues/474
    if (table_exists? :custom_metadata_types)
      drop_table :custom_metadata_types
    end
    create_table :custom_metadata_types do |t|
      t.string :title
      t.integer :contributor_id
      t.text :supported_type
    end
  end

  def down
    drop_table :custom_metadata_types
  end
end
