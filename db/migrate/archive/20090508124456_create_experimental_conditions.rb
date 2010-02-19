class CreateExperimentalConditions < ActiveRecord::Migration
  def self.up
    create_table :experimental_conditions do |t|
      t.integer :measured_item_id
      t.integer :condition_type_id
      t.float :start_value
      t.float :end_value
      t.integer :unit_id
      t.integer :sop_id

      t.timestamps
    end
  end

  def self.down
    drop_table :experimental_conditions
  end
end
