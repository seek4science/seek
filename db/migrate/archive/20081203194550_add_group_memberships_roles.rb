class AddGroupMembershipsRoles < ActiveRecord::Migration
  def self.up
    create_table :group_memberships_roles, :id => false, :force => true do |t|
      t.integer :group_membership_id
      t.integer :role_id
    end
  end

  def self.down
  end
end
