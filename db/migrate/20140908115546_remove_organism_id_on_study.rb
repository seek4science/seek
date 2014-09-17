class RemoveOrganismIdOnStudy < ActiveRecord::Migration
  def up
    remove_column :studies, :organism_id
  end

  def down
    add_column :studies, :organism_id, :integer
  end
end
