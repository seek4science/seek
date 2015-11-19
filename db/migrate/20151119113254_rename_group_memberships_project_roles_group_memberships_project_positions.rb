class RenameGroupMembershipsProjectRolesGroupMembershipsProjectPositions < ActiveRecord::Migration
  def change
    rename_table :group_memberships_project_roles, :group_memberships_project_positions
  end
end
