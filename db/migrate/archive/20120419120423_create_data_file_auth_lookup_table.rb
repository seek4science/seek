class CreateDataFileAuthLookupTable < ActiveRecord::Migration
  def self.up
    create_table :data_file_auth_lookup, :id=>false do |t|
      t.integer :person_id
      t.integer :asset_id
      t.boolean :can_view
      t.boolean :can_manage
      t.boolean :can_edit
      t.boolean :can_download
    end
    add_index :data_file_auth_lookup, [:person_id,:can_view]
  end

  def self.down
    drop_table :data_file_auth_lookup
  end
end
