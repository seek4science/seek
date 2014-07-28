class RemoveUnwantedTreatmentFields < ActiveRecord::Migration
  def change
    remove_column :treatments, :treatment_type_id if column_exists?(:treatments, :treatment_type_id, :integer)
    remove_column :treatments, :incubation_time if column_exists?(:treatments, :incubation_time, :float)
    remove_column :treatments, :incubation_time_unit_id if column_exists?(:treatments, :incubation_time_unit_id, :integer)
    remove_column :treatments, :substance if column_exists?(:treatments, :substance, :string)
    remove_column :treatments, :concentration if column_exists?(:treatments, :concentration, :float)

  end
end
