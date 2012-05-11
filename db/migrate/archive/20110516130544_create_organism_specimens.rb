class CreateOrganismSpecimens < ActiveRecord::Migration
  def self.up
    create_table :organism_specimens do |t|
      t.integer :specimen_id
      t.integer :organism_id
      t.integer :culture_growth_type_id
      t.integer :strain_id

      t.timestamps
    end
  end

  def self.down
    drop_table :organism_specimens
  end
end
