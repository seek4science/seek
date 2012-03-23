class AddParentIdToStrains < ActiveRecord::Migration
  def self.up
    add_column :strains,:parent_id,:integer
  end

  def self.down
    remove_column :strains,:parent_id
  end
end
