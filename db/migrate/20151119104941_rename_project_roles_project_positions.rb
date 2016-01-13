class RenameProjectRolesProjectPositions < ActiveRecord::Migration
  def change
    rename_table :project_roles, :project_positions
  end
end
