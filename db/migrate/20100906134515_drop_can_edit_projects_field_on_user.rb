class DropCanEditProjectsFieldOnUser < ActiveRecord::Migration
  def self.up
    remove_column :users,:can_edit_projects
  end

  def self.down
    add_column :users,:can_edit_projects,:boolean,:default=>false
  end
end
