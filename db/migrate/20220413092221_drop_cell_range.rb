class DropCellRange < ActiveRecord::Migration[6.1]
  def change
    drop_table 'cell_ranges' do |t|
      t.integer :cell_range_id
      t.integer :worksheet_id
      t.integer :start_row
      t.integer :start_column
      t.integer :end_row
      t.integer :end_column
      t.datetime :created_at
      t.datetime :updated_at
    end
  end
end
