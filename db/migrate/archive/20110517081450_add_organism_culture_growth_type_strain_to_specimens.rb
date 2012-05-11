class AddOrganismCultureGrowthTypeStrainToSpecimens < ActiveRecord::Migration
  def self.up
    add_column :specimens,:organism_id,:integer
    add_column :specimens,:culture_growth_type_id,:integer
    add_column :specimens,:strain_id,:integer
  end

  def self.down
    remove_column :specimens,:organism_id
    remove_column :specimens,:culture_growth_type_id
    remove_column :specimens,:strain_id
  end
end
