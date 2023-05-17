class CreateCustomMetadataResourceLinks < ActiveRecord::Migration[6.1]
  def change
    create_table :custom_metadata_resource_links do |t|
      t.references :custom_metadata
      t.references :resource, polymorphic: true
    end
  end
end
