class CreateAssetsLinks < ActiveRecord::Migration[5.2]
  def change
    create_table :assets_links do |t|
      t.integer :asset_id
      t.string :asset_type
      t.string :url
      t.string :link_type

      t.timestamps
    end
    add_index :assets_links, [:asset_id, :asset_type]
  end
end
