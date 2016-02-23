class CreateSampleAuthLookup < ActiveRecord::Migration
  def change
    remove_index :deprecated_sample_auth_lookup, name: "index_sample_user_id_asset_id_can_view"
    remove_index :deprecated_sample_auth_lookup, name: "index_sample_auth_lookup_on_user_id_and_can_view"

    create_table :sample_auth_lookup,:id=>false do |t|
      t.integer :user_id
      t.integer :asset_id
      t.boolean :can_view,     :default => false
      t.boolean :can_manage,   :default => false
      t.boolean :can_edit,     :default => false
      t.boolean :can_download, :default => false
      t.boolean :can_delete,   :default => false
    end

    add_index :sample_auth_lookup, [:user_id, :asset_id, :can_view], :name => "index_sample_user_id_asset_id_can_view"
    add_index :sample_auth_lookup, [:user_id, :can_view], :name => "index_sample_auth_lookup_on_user_id_and_can_view"
  end

end
