class DropOrganismAndStrainFieldFromSpecimens < ActiveRecord::Migration
  def self.up
    remove_column :specimens,:organism_id
    remove_column :specimens,:strain_id
  end

  def self.down
    add_column :specimens,:organism_id,:integer
    add_column :specimens,:strain_id,:integer
  end
end
