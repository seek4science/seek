class CreateCustomMetadata < ActiveRecord::Migration[5.2]
  def change
    create_table :custom_metadata do |t|
      t.text :json_metadata
      t.references :item, polymorphic:true, index:true
      t.references :custom_metadata_type
    end
  end
end
