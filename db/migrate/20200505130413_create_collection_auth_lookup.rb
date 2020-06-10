class CreateCollectionAuthLookup < ActiveRecord::Migration[5.2]
  def change
    create_table :collection_auth_lookup do |t|
      t.integer :user_id
      t.integer :asset_id
      t.boolean :can_view,     :default => false
      t.boolean :can_manage,   :default => false
      t.boolean :can_edit,     :default => false
      t.boolean :can_download, :default => false
      t.boolean :can_delete,   :default => false
    end

    add_index :collection_auth_lookup, [:user_id, :asset_id, :can_view], name: 'index_collection_user_id_asset_id_can_view'
    add_index :collection_auth_lookup, [:user_id, :can_view], name: 'index_collection_auth_lookup_on_user_id_and_can_view'
  end
end
