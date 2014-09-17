class RemoveUnwantedTreatmentFields < ActiveRecord::Migration
  def change
    #this is to get around an inconsistency between VLN and SEEK schema. the next migration that creates measured_item_id will skip it if it exists.
    if column_exists?(:treatments, :treatment_type_id, :integer)
      rename_column :treatments, :treatment_type_id, :measured_item_id
    end
    remove_column :treatments, :substance if column_exists?(:treatments, :substance, :string)
    remove_column :treatments, :concentration if column_exists?(:treatments, :concentration, :float)
  end
end
