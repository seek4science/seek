class RemoveExperimentsSops < ActiveRecord::Migration
  def self.up
    drop_table(:experiments_sops)
  end

  def self.down
    create_table "experiments_sops", :id => false do |t|
    t.integer "experiment_id"
    t.integer "sop_id"
  end
  end
end
