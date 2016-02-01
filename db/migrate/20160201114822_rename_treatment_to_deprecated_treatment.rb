class RenameTreatmentToDeprecatedTreatment < ActiveRecord::Migration

  def change
    rename_table :treatments,:deprecated_treatments
  end

end
