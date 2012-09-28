class AddSamplingDateToSamples < ActiveRecord::Migration
  def self.up
    add_column :samples, :sampling_date, :datetime
  end

  def self.down
    remove_column :samples, :sampling_date
  end
end
