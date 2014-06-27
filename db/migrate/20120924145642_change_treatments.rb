class ChangeTreatments < ActiveRecord::Migration
  def self.up
    change_table :treatments do |t|
      t.remove :substance, :concentration
      t.integer :treatment_type_id
      t.float :start_value
      t.float :end_value
      t.float :standard_deviation
      t.text :comments
      t.float :incubation_time
      t.integer :incubation_time_unit_id
      t.integer :sample_id
      t.integer :specimen_id
      t.integer :compound_id
    end
  end

  def self.down
    change_table :treatments do |t|
      t.string :substance
      t.float :concentration
      t.remove :treatment_type_id, :start_value, :end_value, :standard_deviation, :comments, :incubation_time, :incubation_time_unit_id
      t.remove :sample_id
      t.remove :specimen_id
      t.remove :compound_id
    end
  end
end
