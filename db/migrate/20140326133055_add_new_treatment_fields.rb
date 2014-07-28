class AddNewTreatmentFields < ActiveRecord::Migration

  def change
    add_column :treatments, :measured_item_id, :integer if !column_exists?(:treatments,:sample_id,:integer)
    add_column :treatments, :start_value,:float if !column_exists?(:treatments,:start_value,:float)
    add_column :treatments, :end_value, :float if !column_exists?(:treatments,:end_value,:float)
    add_column :treatments, :standard_deviation, :float if !column_exists?(:treatments,:standard_deviation,:float)
    add_column :treatments, :comments, :text  if !column_exists?(:treatments,:comments,:text)
    add_column :treatments, :compound_id, :integer if !column_exists?(:treatments,:compound_id,:integer)


  end

end
