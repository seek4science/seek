class UpdateSampleAgeAtSamplingToBeString < ActiveRecord::Migration
  def up
    change_column :samples, :age_at_sampling, :string
  end

  def down
    change_column :samples, :age_at_sampling, :float
  end

end
