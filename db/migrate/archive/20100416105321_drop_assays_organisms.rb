class DropAssaysOrganisms < ActiveRecord::Migration
  def self.up
    drop_table :assays_organisms
  end
  
  def self.down
    create_table :assays_organisms,:id=>false do |t|
      t.integer :assay_id
      t.integer :organism_id
    end
  end
  
end
