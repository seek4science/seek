class MoveOrganismFromSopToAssay < ActiveRecord::Migration
  def self.up
    remove_column :sops,:organism_id
    add_column :assays,:organism_id,:integer
  end

  def self.down
    remove_column :assays,:organism_id
    add_column :sops,:organism_id,:integer
  end
end
