class RemoveOrganismFromAssay < ActiveRecord::Migration
  def self.up
    remove_column(:assays, :organism_id)
  end

  def self.down
    add_column :assays, :organism_id, :integer
  end
end
