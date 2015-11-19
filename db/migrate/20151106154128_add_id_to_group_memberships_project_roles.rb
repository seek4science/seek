class AddIdToGroupMembershipsProjectRoles < ActiveRecord::Migration
  def change
    add_column :group_memberships_project_positions, :id, :primary_key
  end
end
