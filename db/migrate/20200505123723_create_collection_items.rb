class CreateCollectionItems < ActiveRecord::Migration[5.2]
  def change
    create_table :collection_items do |t|
      t.references :collection, index: true
      t.references :asset, polymorphic: true, index: true
      t.text :comment
      t.integer :order
      t.timestamps
    end
  end
end
