class RemoveUnwantedTreatmentFields < ActiveRecord::Migration
  def change
    remove_column :treatments, :substance
    remove_column :treatments, :concentration
  end
end
