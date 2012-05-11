class AddIsProjectManagerFlagToPerson < ActiveRecord::Migration
  def self.up
    add_column :people, :is_project_manager, :boolean, :default=>false
  end

  def self.down
    remove_column :people, :is_project_manager
  end
end
