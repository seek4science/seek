class CreateSpreadsheetAnnotations < ActiveRecord::Migration
  def self.up
    create_table :spreadsheet_annotations do |t|
      t.integer :data_file_id
      t.integer :sheet
      t.integer :start_row
      t.integer :start_column
      t.integer :end_row
      t.integer :end_column      
      t.integer :source_id
      t.integer :source_type
      t.string  :type
      t.text    :content
      t.timestamps
    end
  end

  def self.down
    drop_table :spreadsheet_annotations
  end
end
