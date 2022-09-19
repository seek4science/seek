class CreateTemplateAuthLookup < ActiveRecord::Migration[5.2]
  def change
    create_table :template_auth_lookup, {:id => false} do |t|
      t.integer :user_id
      t.integer :asset_id
      t.boolean :can_view,     :default => false
      t.boolean :can_manage,   :default => false
      t.boolean :can_edit,     :default => false
      t.boolean :can_download, :default => false
      t.boolean :can_delete,   :default => false
      t.integer :id, primary_key: true
    end
    add_index :template_auth_lookup, [:user_id, :asset_id, :can_view], name: 'index_template_auth_lookup_user_id_asset_id'
    add_index :template_auth_lookup, [:user_id, :can_view], name: 'index_template_auth_lookup_on_user_id_and_can_view'
  end
end
