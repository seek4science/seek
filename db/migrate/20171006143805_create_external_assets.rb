class CreateExternalAssets < ActiveRecord::Migration
  def change
    create_table :external_assets do |t|
      t.string :external_service, null: false
      t.string :external_id, null: false
      t.string :external_mod_stamp
      t.datetime :synchronized_at
      t.integer :sync_state, null: false, default: 0, limit: 1
      t.references :seek_entity, polymorphic: true, index: true
      t.integer :version, null:false, default: 0
      t.string :class_type

      t.timestamps null: false
    end
    add_index :external_assets, [:external_id, :external_service], unique: true, name: 'external_assets_by_external_id'
  end
end
