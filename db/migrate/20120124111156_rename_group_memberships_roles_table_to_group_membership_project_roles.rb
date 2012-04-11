class RenameGroupMembershipsRolesTableToGroupMembershipProjectRoles < ActiveRecord::Migration
  def self.up
    rename_table :group_memberships_roles, :group_memberships_project_roles
  end

  def self.down
    rename_table :group_memberships_project_roles, :group_memberships_roles
  end
end
