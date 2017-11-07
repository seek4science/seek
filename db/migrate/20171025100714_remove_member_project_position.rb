class RemoveMemberProjectPosition < ActiveRecord::Migration
  def up
    id=select_value("SELECT id FROM project_positions WHERE name = 'Member';")
    if id
      execute("DELETE FROM project_positions WHERE id = #{id};")
      execute("DELETE FROM group_memberships_project_positions WHERE project_position_id = #{id};")
    end
  end

  def down

  end
end
