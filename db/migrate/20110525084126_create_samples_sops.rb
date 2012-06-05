class CreateSamplesSops < ActiveRecord::Migration
  def self.up
    create_table :sample_sops do |t|
      t.integer :sample_id
      t.integer :sop_id
      t.integer :sop_version
    end
  end

  def self.down
    drop_table :sample_sops
  end
end
