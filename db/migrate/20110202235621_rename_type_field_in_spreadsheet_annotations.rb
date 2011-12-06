class RenameTypeFieldInSpreadsheetAnnotations < ActiveRecord::Migration
  def self.up
    rename_column(:spreadsheet_annotations, :type, :annotation_type)
  end

  def self.down
    rename_column(:spreadsheet_annotations, :annotation_type, :type)
  end
end
