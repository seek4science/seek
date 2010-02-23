class RemoveAssaysExperiments < ActiveRecord::Migration
  def self.up
    drop_table :assays_experiments
  end

  def self.down
    create_table "assays_experiments", :id => false do |t|
    t.integer "experiment_id"
    t.integer "assay_id"
  end
  end
end
