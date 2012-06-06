class CreateCellRange < ActiveRecord::Migration
  def self.up
    create_table :cell_ranges do |t|
      t.integer :cell_range_id
      t.integer :worksheet_id
      t.integer :start_row
      t.integer :start_column
      t.integer :end_row
      t.integer :end_column
      t.timestamps
    end
  end

  def self.down
    drop_table :cell_ranges
  end
end
