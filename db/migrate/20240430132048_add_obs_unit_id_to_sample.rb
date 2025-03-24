class AddObsUnitIdToSample < ActiveRecord::Migration[6.1]
  def change
    add_column :samples, :observation_unit_id, :bigint
  end
end
