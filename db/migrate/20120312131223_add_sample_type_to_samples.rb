class AddSampleTypeToSamples < ActiveRecord::Migration
  def self.up
    add_column :samples, :sample_type, :string
  end

  def self.down
    remove_column :samples, :sample_type
  end
end
