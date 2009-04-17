class CreateAssaysExperiments < ActiveRecord::Migration
  def self.up
    create_table :assays_experiments,:id=>false do |t|
      t.integer :experiment_id
      t.integer :assay_id
    end
  end

  def self.down
    drop_table :assays_experiments
  end
end
