class ChangeSpreadsheetAnnotationsSourceTypeToString < ActiveRecord::Migration
  def self.up
    remove_column :spreadsheet_annotations,:source_type
    add_column :spreadsheet_annotations,:source_type,:string
  end

  def self.down
    remove_column :spreadsheet_annotations,:source_type
    add_column :spreadsheet_annotations,:source_type,:integer
  end
end
