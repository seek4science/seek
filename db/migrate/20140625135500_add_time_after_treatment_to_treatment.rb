class AddTimeAfterTreatmentToTreatment < ActiveRecord::Migration
  def change
    add_column :treatments,:time_after_treatment,:float
    add_column :treatments, :time_after_treatment_unit_id,:integer
  end
end
