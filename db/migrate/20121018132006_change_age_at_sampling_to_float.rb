class ChangeAgeAtSamplingToFloat < ActiveRecord::Migration
  def self.up
    change_column :samples, :age_at_sampling, :float
  end

  def self.down
    change_column :samples, :age_at_sampling, :integer
  end
end
