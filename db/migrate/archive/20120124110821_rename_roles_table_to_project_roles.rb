class RenameRolesTableToProjectRoles < ActiveRecord::Migration
  def self.up
    rename_table :roles, :project_roles
  end

  def self.down
    rename_table :project_roles, :roles
  end
end
