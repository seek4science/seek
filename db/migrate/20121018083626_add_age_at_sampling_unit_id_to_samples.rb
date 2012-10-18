class AddAgeAtSamplingUnitIdToSamples < ActiveRecord::Migration
  def self.up
    add_column :samples, :age_at_sampling_unit_id, :integer
  end

  def self.down
    remove_column :samples, :age_at_sampling_unit_id
  end
end
