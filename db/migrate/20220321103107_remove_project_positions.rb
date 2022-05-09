class RemoveProjectPositions < ActiveRecord::Migration[6.1]
  def change
    drop_table "group_memberships_project_positions" do |t|
      t.integer "group_membership_id"
      t.integer "project_position_id"
    end

    drop_table "project_positions" do |t|
      t.string "name"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

  end
end
