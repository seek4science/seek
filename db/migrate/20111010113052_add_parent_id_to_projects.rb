class AddParentIdToProjects < ActiveRecord::Migration
  def self.up
    add_column :projects,:parent_id,:integer
  end

  def self.down
    remove_column :projects,:parent_id
  end
end
