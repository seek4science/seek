class CreateStudiedFactors < ActiveRecord::Migration
  def self.up
    create_table :studied_factors do |t|
      t.integer :measured_item_id
      t.integer :factor_type_id
      t.float :start_value
      t.float :end_value
      t.integer :unit_id
      t.integer :time_point
      t.integer :data_file_id

      t.timestamps
    end
  end

  def self.down
    drop_table :studied_factors
  end
end
