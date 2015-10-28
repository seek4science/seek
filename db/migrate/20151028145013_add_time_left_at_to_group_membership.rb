class AddTimeLeftAtToGroupMembership < ActiveRecord::Migration
  def change
    add_column :group_memberships, :time_left_at, :datetime
  end
end
