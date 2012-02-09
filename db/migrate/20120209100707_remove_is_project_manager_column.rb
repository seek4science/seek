class RemoveIsProjectManagerColumn < ActiveRecord::Migration
  def self.up
    remove_column :people, :is_project_manager
  end

  def self.down
    add_column :people, :is_project_manager, :boolean, :default => false
  end
end
