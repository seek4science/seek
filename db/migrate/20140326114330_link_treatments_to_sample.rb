class LinkTreatmentsToSample < ActiveRecord::Migration

  def change
    add_column :treatments,:sample_id,:integer
  end

end
