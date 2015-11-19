class RenameProjectRoleIdProjectPositionIdInGroupMembershipsProjectPositions < ActiveRecord::Migration
  def change
    rename_column :group_memberships_project_positions, :project_role_id, :project_position_id
  end
end
