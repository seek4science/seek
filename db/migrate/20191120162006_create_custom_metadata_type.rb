class CreateCustomMetadataType < ActiveRecord::Migration[5.2]
  def change
    create_table :custom_metadata_types do |t|
      t.string :title
      t.integer :contributor_id
      t.text :supported_type
    end
  end
end
