class AddHasLeftToGroupMemberships < ActiveRecord::Migration
  def change
    add_column :group_memberships, :has_left, :boolean, :default => false
  end
end
