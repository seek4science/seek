class CreateSpreadsheets < ActiveRecord::Migration
  def self.up
    create_table :spreadsheets do |t|
      t.integer :data_file_id
      t.integer :content_blob_id
      t.timestamps
    end
  end

  def self.down
    drop_table :spreadsheets
  end
end
