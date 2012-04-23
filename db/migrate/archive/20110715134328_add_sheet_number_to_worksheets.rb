class AddSheetNumberToWorksheets < ActiveRecord::Migration
  def self.up
    add_column :worksheets, :sheet_number, :integer
  end

  def self.down
    remove_column :worksheets, :sheet_number
  end
end
