class AddOrganismToSop < ActiveRecord::Migration
  def self.up
    add_column :sops, :organism_id, :integer
  end

  def self.down
    remove_column :sops,:organism_id
  end
end
