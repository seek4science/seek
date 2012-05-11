class CreateStrainAuthLookupTable < ActiveRecord::Migration
  def self.up
    create_table :strain_auth_lookup, :id=>false do |t|
          t.integer :user_id
          t.integer :asset_id
          t.boolean :can_view, :default=>false
          t.boolean :can_manage, :default=>false
          t.boolean :can_edit, :default=>false
          t.boolean :can_download, :default=>false
          t.boolean :can_delete, :default=>false
        end
        add_index :strain_auth_lookup, [:user_id,:can_view]
  end

  def self.down
    drop_table :strain_auth_lookup
  end
end
