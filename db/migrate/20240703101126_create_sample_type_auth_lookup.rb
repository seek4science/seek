class CreateSampleTypeAuthLookup < ActiveRecord::Migration[6.1]
  def change
    create_table :sample_type_auth_lookups do |t|
      t.integer :user_id
      t.integer :asset_id
      t.boolean :can_view,     :default => false
      t.boolean :can_manage,   :default => false
      t.boolean :can_edit,     :default => false
      t.boolean :can_download, :default => false
      t.boolean :can_delete,   :default => false
      t.timestamps
    end
    add_index :sample_type_auth_lookup, [:user_id, :asset_id, :can_view], :name => "index_sample_type_user_id_asset_id_can_view"
    add_index :sample_type_auth_lookup, [:user_id, :can_view], :name => "index_sample_type_auth_lookup_on_user_id_and_can_view"
    add_column :sample_types, :policy_id, :integer
  end
end
