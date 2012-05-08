class CreateAssaysSamples < ActiveRecord::Migration
  def self.up
    create_table :assays_samples, :id => false do |t|
      t.integer :assay_id
      t.integer :sample_id
    end
  end

  def self.down
    drop_table :assays_samples
  end
end
