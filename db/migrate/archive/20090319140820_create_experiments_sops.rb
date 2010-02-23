class CreateExperimentsSops < ActiveRecord::Migration
  def self.up
    create_table :experiments_sops,:id=>false do |t|
      t.integer :experiment_id
      t.integer :sop_id
    end
  end

  def self.down
    drop_table :experiments_sops
  end
end
