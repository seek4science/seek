class LinkTreatmentsToSample < ActiveRecord::Migration

  def change
    add_column :treatments,:sample_id,:integer if !column_exists?(:treatments,:sample_id,:integer)
  end

end
