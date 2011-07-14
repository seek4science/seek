class DropOrganismSpecimens < ActiveRecord::Migration
  def self.up
    drop_table :organism_specimens
  end

  def self.down
    create_table :organism_specimens do |t|
      t.integer :specimen_id
      t.integer :organism_id
      t.integer :culture_growth_type_id
      t.integer :strain_id

      t.timestamps
    end
  end
end
