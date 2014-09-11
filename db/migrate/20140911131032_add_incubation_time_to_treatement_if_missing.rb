class AddIncubationTimeToTreatementIfMissing < ActiveRecord::Migration
  def change
    add_column :treatments, :incubation_time, :float if !column_exists?(:treatments,:incubation_time, :float)
    add_column :treatments, :incubation_time_unit_id, :float if !column_exists?(:treatments,:incubation_time_unit_id, :integer)
  end
end
