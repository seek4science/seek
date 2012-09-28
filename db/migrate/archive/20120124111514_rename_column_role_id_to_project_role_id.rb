class RenameColumnRoleIdToProjectRoleId < ActiveRecord::Migration
  def self.up
    rename_column :group_memberships_project_roles, :role_id, :project_role_id
  end

  def self.down
    rename_column :group_memberships_project_roles, :project_role_id, :role_id
  end
end
