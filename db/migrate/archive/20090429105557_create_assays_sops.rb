class CreateAssaysSops < ActiveRecord::Migration
  def self.up
    create_table :assays_sops,:id=>false do |t|
      t.integer :assay_id
      t.integer :sop_id
    end
  end

  def self.down
    drop_table :assays_sops
  end
end
