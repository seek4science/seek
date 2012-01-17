class RemoveOrganismFromSpecimen < ActiveRecord::Migration
  def self.up
    remove_column :specimens,:organism_id
  end

  def self.down
    add_column :specimens, :organism_id, :integer
  end
end
