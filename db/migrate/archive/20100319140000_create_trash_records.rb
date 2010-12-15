class CreateTrashRecords < ActiveRecord::Migration
  
  def self.up
    create_table :trash_records do |t|
      t.column :trashable_type, :string
      t.column :trashable_id, :integer
      t.column :data, :binary, :limit => 5.megabytes
      t.column :created_at, :timestamp
    end
    
    add_index :trash_records, [:trashable_type, :trashable_id]
    add_index :trash_records, [:created_at, :trashable_type]
  end
  
  def self.down
    drop_table :trash_records
  end

end
