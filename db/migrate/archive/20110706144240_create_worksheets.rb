class CreateWorksheets < ActiveRecord::Migration
  def self.up
    create_table :worksheets do |t|
      t.integer :spreadsheet_id
      t.integer :last_row
      t.integer :last_column
    end
  end

  def self.down
    drop_table :worksheets
  end
end
