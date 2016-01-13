class CreateSnapshots < ActiveRecord::Migration
  def change
    create_table :snapshots do |t|
      t.string :resource_type
      t.integer :resource_id
      t.string :doi
      t.integer :snapshot_number

      t.timestamps
    end
  end
end
