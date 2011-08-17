class LinkWorksheetsToContentBlob < ActiveRecord::Migration
  def self.up
    rename_column :worksheets, :spreadsheet_id, :content_blob_id
  end

  def self.down
    rename_column :worksheets, :content_blob_id, :spreadsheet_id
  end
end
