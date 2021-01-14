class ReAddHasLeftToGroupMemberships < ActiveRecord::Migration[5.2]
  def change
    add_column :group_memberships, :has_left, :boolean, default: false
    GroupMembership.update_all(has_left: false)
  end
end
