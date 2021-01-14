class CreateCustomMetadata < ActiveRecord::Migration[5.2]
  def up
    # see https://github.com/seek4science/seek/issues/474
    if (table_exists? :custom_metadata)
      drop_table :custom_metadata
    end

    create_table :custom_metadata do |t|
      t.text :json_metadata
      t.references :item, polymorphic:true, index:true
      t.references :custom_metadata_type
    end
  end

  def down
    drop_table :custom_metadata
  end
end
