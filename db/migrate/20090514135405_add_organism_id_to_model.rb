class AddOrganismIdToModel < ActiveRecord::Migration

  def self.up
    add_column :models, :organism_id, :integer
  end

  def self.down
    remove_column :models,:organism_id
  end

end
