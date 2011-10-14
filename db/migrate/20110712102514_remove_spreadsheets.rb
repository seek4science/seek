class RemoveSpreadsheets < ActiveRecord::Migration
  def self.up
    drop_table :spreadsheets
  end

  def self.down
    create_table :spreadsheets do |t|
      t.integer :data_file_id
      t.integer :content_blob_id
      t.timestamps
    end
  end
end
