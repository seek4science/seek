class AddIndexForAvatarOwner < ActiveRecord::Migration
  def self.up
    add_index :avatars,[:owner_type,:owner_id]
  end

  def self.down
    remove_index :avatars,[:owner_type,:owner_id]
  end
end
