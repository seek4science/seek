class AddAgeAtSamplingToSamples < ActiveRecord::Migration
  def self.up
    add_column :samples, :age_at_sampling, :integer
  end

  def self.down
    remove_column :samples, :age_at_sampling
  end
end
