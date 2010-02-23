class DropAssaysSops < ActiveRecord::Migration
  def self.up
    drop_table :assays_sops
  end

  def self.down
    create_table "assays_sops", :id => false, :force => true do |t|
      t.integer "assay_id"
      t.integer "sop_id"
    end
  end
end
