class RemoveHasLeftFromGroupMemberships < ActiveRecord::Migration
  def change
    remove_column :group_memberships, :has_left
  end
end
