class AddUnitIdToSampleAttributes < ActiveRecord::Migration
  def change
    add_column :sample_attributes, :unit_id, :integer
    add_index :sample_attributes, [:unit_id]
  end
end
