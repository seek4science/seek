class RemoveSpreadsheetAnnotations < ActiveRecord::Migration
  def self.up
    drop_table :spreadsheet_annotations
  end

  def self.down
    t.integer :data_file_id
    t.integer :sheet
    t.integer :start_row
    t.integer :start_column
    t.integer :end_row
    t.integer :end_column
    t.integer :source_id
    t.string :source_type
    t.string  :type
    t.text    :content
    t.timestamps
  end
end
