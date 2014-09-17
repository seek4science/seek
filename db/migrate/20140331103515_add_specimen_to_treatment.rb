class AddSpecimenToTreatment < ActiveRecord::Migration
  def change
    add_column :treatments, :specimen_id, :integer if !column_exists?(:treatments,:specimen_id,:integer)
  end
end
