class CreateAssaysOrganismsJoinTable < ActiveRecord::Migration
  def self.up
    create_table :assays_organisms,:id=>false do |t|
      t.integer :assay_id
      t.integer :organism_id
    end
  end

  def self.down
    drop_table :assays_organisms
  end
end
