class RemoveCustomMetadataResourceLink < ActiveRecord::Migration[6.1]
  def up
    drop_table :custom_metadata_resource_links
  end

  def down
    create_table :custom_metadata_resource_links do |t|
      t.references :custom_metadata
      t.references :resource, polymorphic: true
    end
  end
end
