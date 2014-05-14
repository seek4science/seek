class AddProjectAncestorAndDescendant < ActiveRecord::Migration
  def change
    add_column :projects,:ancestor_id,:integer
  end

end
